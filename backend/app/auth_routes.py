import hmac
import re
import secrets
import time

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session, select

from app.database import get_session
from app.models import AccesoGestante, Gestante, PersonalSalud, SesionWeb, VinculacionMovil
from app.schemas import CambiarPinPayload, LoginPayload, RegistroMovilPayload
from app.security import (COOKIE_NAME, SESSION_SECONDS, check_attempt, clear_attempt, current_user,
                          digest, failed_attempt, hash_password, require_admin, secure_cookie,
                          verify_password)

router = APIRouter()


def session_data(user, csrf):
    return {"ok": True, "dni": user.dni, "nombre": user.nombre, "rol": user.rol,
            "csrf_token": csrf}


def new_session(user, session, response, request):
    token = secrets.token_urlsafe(32)
    csrf = digest("csrf:" + token)
    session.add(SesionWeb(token_hash=digest(token), personal_id=user.id,
                         csrf_hash=digest(csrf), expira_en=int(time.time()) + SESSION_SECONDS))
    session.commit()
    response.set_cookie(COOKIE_NAME, token, max_age=SESSION_SECONDS, httponly=True,
                        secure=secure_cookie() or request.url.scheme == "https", samesite="strict", path="/api")
    response.headers["Cache-Control"] = "no-store"
    return session_data(user, csrf)


@router.post("/api/login")
def login(payload: LoginPayload, request: Request, response: Response, session: Session = Depends(get_session)):
    key = f"login:{payload.dni}"
    ip_key = f"login-ip:{request.client.host if request.client else 'unknown'}"
    check_attempt(session, key)
    check_attempt(session, ip_key)
    user = session.exec(select(PersonalSalud).where(PersonalSalud.dni == payload.dni)).first()
    # Mismo coste y mensaje si el DNI no existe; no permite enumerar cuentas.
    stored = user.pin if user else "pbkdf2_sha256$600000$dummy$" + "0" * 64
    valid = verify_password(payload.pin, stored)
    if not user or not valid or not user.activo or user.rol not in {"medico", "admin"}:
        failed_attempt(session, key)
        failed_attempt(session, ip_key)
        raise HTTPException(401, "DNI o PIN incorrectos.")
    clear_attempt(session, key)
    clear_attempt(session, ip_key)
    previous = request.cookies.get(COOKIE_NAME)
    if previous:
        existing = session.get(SesionWeb, digest(previous))
        if existing:
            session.delete(existing)
    return new_session(user, session, response, request)


@router.get("/api/sesion")
def get_current_session(request: Request, response: Response, user=Depends(current_user), session: Session = Depends(get_session)):
    csrf = digest("csrf:" + request.cookies[COOKIE_NAME])
    response.headers["Cache-Control"] = "no-store"
    return session_data(user, csrf)


@router.post("/api/logout")
def logout(request: Request, response: Response, user=Depends(current_user), session: Session = Depends(get_session)):
    row = session.get(SesionWeb, digest(request.cookies[COOKIE_NAME]))
    session.delete(row)
    session.commit()
    response.delete_cookie(COOKIE_NAME, path="/api", secure=secure_cookie() or request.url.scheme == "https", httponly=True, samesite="strict")
    return {"ok": True}


@router.post("/api/cambiar-pin")
def change_pin(payload: CambiarPinPayload, request: Request, response: Response, user=Depends(current_user), session: Session = Depends(get_session)):
    key = f"pin-change:{user.id}"
    check_attempt(session, key)
    if not verify_password(payload.actual, user.pin):
        failed_attempt(session, key)
        raise HTTPException(400, "El PIN actual no es correcto.")
    if payload.actual == payload.nueva:
        raise HTTPException(400, "El nuevo PIN debe ser diferente al actual.")
    user.pin = hash_password(payload.nueva)
    session.add(user)
    for row in session.exec(select(SesionWeb).where(SesionWeb.personal_id == user.id)).all():
        session.delete(row)
    session.commit()
    clear_attempt(session, key)
    # Revoca también las demás sesiones del usuario.
    return new_session(user, session, response, request)


def mobile_patient(request: Request, session: Session = Depends(get_session)) -> Gestante:
    authorization = request.headers.get("Authorization", "")
    dni = request.headers.get("X-Profile-DNI", "")
    key = authorization.removeprefix("Bearer ") if authorization.startswith("Bearer ") else ""
    if not re.fullmatch(r"[0-9]{8}", dni) or not re.fullmatch(r"[A-Za-z0-9_-]{43}", key):
        raise HTTPException(401, "La cuenta no está vinculada para sincronizar.")
    patient = session.exec(select(Gestante).where(Gestante.dni == dni)).first()
    if not patient or not patient.sync_key_hash or not hmac.compare_digest(patient.sync_key_hash, digest(key)):
        raise HTTPException(401, "La cuenta no está vinculada para sincronizar.")
    return patient


@router.post("/api/mobile/registro")
def mobile_register(payload: RegistroMovilPayload, request: Request, session: Session = Depends(get_session)):
    rate_key = f"enroll:{request.client.host if request.client else 'unknown'}"
    patient = session.exec(select(Gestante).where(Gestante.dni == payload.perfil.dni)).first()
    if patient and patient.sync_key_hash and hmac.compare_digest(patient.sync_key_hash, digest(payload.sync_key)):
        return {"ok": True, "server_id": str(patient.id), "message": "Cuenta vinculada."}
    check_attempt(session, rate_key)
    if patient:
        code = session.get(VinculacionMovil, digest(payload.codigo_vinculacion)) if payload.codigo_vinculacion else None
        if not code or code.gestante_id != patient.id or code.expira_en <= int(time.time()):
            if payload.codigo_vinculacion:
                failed_attempt(session, rate_key)
            raise HTTPException(409, "Esta cuenta central necesita un código de vinculación del administrador.")
        session.delete(code)
        patient.sync_key_hash = digest(payload.sync_key)
    else:
        values = payload.perfil.model_dump(mode="json")
        patient = Gestante(**values, sync_key_hash=digest(payload.sync_key))
    session.add(patient)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        raise HTTPException(409, "El perfil ya fue registrado. Vuelve a intentar la vinculación.")
    return {"ok": True, "server_id": str(patient.id), "message": "Cuenta vinculada."}


@router.post("/api/gestantes/{patient_id}/vinculacion")
def create_pairing(patient_id: int, user=Depends(require_admin), session: Session = Depends(get_session)):
    if not session.get(Gestante, patient_id):
        raise HTTPException(404, "Gestante no encontrada.")
    for old in session.exec(select(VinculacionMovil).where(VinculacionMovil.gestante_id == patient_id)).all():
        session.delete(old)
    code = secrets.token_urlsafe(24)
    session.add(VinculacionMovil(codigo_hash=digest(code), gestante_id=patient_id, expira_en=int(time.time()) + 600))
    session.commit()
    return {"codigo": code, "vigencia_segundos": 600}


@router.put("/api/gestantes/{patient_id}/acceso/{dni}")
def assign_access(patient_id: int, dni: str, user=Depends(require_admin), session: Session = Depends(get_session)):
    if not session.get(Gestante, patient_id):
        raise HTTPException(404, "Gestante no encontrada.")
    doctor = session.exec(select(PersonalSalud).where(PersonalSalud.dni == dni, PersonalSalud.activo == True)).first()
    if not doctor or doctor.rol != "medico":
        raise HTTPException(404, "Profesional activo no encontrado.")
    existing = session.exec(select(AccesoGestante).where(AccesoGestante.personal_id == doctor.id,
                                                       AccesoGestante.gestante_id == patient_id)).first()
    if not existing:
        session.add(AccesoGestante(personal_id=doctor.id, gestante_id=patient_id))
        try:
            session.commit()
        except IntegrityError:
            session.rollback()
    return {"ok": True}


@router.delete("/api/gestantes/{patient_id}/acceso/{dni}")
def revoke_access(patient_id: int, dni: str, user=Depends(require_admin), session: Session = Depends(get_session)):
    doctor = session.exec(select(PersonalSalud).where(PersonalSalud.dni == dni)).first()
    if doctor:
        grants = session.exec(select(AccesoGestante).where(AccesoGestante.personal_id == doctor.id,
                                                         AccesoGestante.gestante_id == patient_id)).all()
        for grant in grants:
            session.delete(grant)
        session.commit()
    return {"ok": True}
