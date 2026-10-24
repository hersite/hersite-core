"""Sesiones revocables, credenciales derivadas y autorización del servidor."""
import hashlib
import hmac
import os
import secrets
import time

from fastapi import Depends, HTTPException, Request
from sqlmodel import Session, select

from app.database import get_session
from app.models import AccesoGestante, IntentoAcceso, PersonalSalud, SesionWeb

COOKIE_NAME = "hersite_session"
SESSION_SECONDS = 8 * 60 * 60
ITERATIONS = 600_000


def digest(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    derived = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), ITERATIONS)
    return f"pbkdf2_sha256${ITERATIONS}${salt}${derived.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        algorithm, rounds, salt, expected = stored.split("$")
        if algorithm != "pbkdf2_sha256" or int(rounds) != ITERATIONS:
            return False
        actual = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), int(rounds))
        return hmac.compare_digest(actual.hex(), expected)
    except (ValueError, TypeError):
        return False


def check_attempt(session: Session, key: str) -> None:
    row = session.get(IntentoAcceso, digest(key))
    if row and row.bloqueado_hasta > int(time.time()):
        raise HTTPException(429, "Demasiados intentos. Vuelve a intentarlo en unos minutos.",
                            headers={"Retry-After": str(row.bloqueado_hasta - int(time.time()))})


def failed_attempt(session: Session, key: str) -> None:
    now = int(time.time())
    row = session.get(IntentoAcceso, digest(key)) or IntentoAcceso(clave=digest(key), ventana_inicio=now)
    if now - row.ventana_inicio >= 900:
        row.intentos = 0
        row.ventana_inicio = now
    row.intentos += 1
    if row.intentos >= 5:
        row.bloqueado_hasta = now + 900
    session.add(row)
    session.commit()


def clear_attempt(session: Session, key: str) -> None:
    row = session.get(IntentoAcceso, digest(key))
    if row:
        session.delete(row)
        session.commit()


def current_user(request: Request, session: Session = Depends(get_session)) -> PersonalSalud:
    token = request.cookies.get(COOKIE_NAME, "")
    stored = session.get(SesionWeb, digest(token)) if token else None
    if not stored or stored.expira_en <= int(time.time()):
        raise HTTPException(401, "La sesión expiró. Ingresa nuevamente.")
    user = session.get(PersonalSalud, stored.personal_id)
    if not user or not user.activo or user.rol not in {"medico", "admin"}:
        raise HTTPException(401, "La sesión no es válida.")
    if request.method not in {"GET", "HEAD", "OPTIONS"}:
        csrf = request.headers.get("X-CSRF-Token", "")
        if not csrf or not hmac.compare_digest(digest(csrf), stored.csrf_hash):
            raise HTTPException(403, "No se pudo verificar la solicitud.")
    return user


def require_admin(user: PersonalSalud = Depends(current_user)) -> PersonalSalud:
    if user.rol != "admin":
        raise HTTPException(403, "Esta operación requiere permisos de administrador.")
    return user


def visible_ids(user: PersonalSalud, session: Session) -> list[int] | None:
    if user.rol == "admin":
        return None
    return list(session.exec(select(AccesoGestante.gestante_id).where(AccesoGestante.personal_id == user.id)).all())


def require_patient(user: PersonalSalud, session: Session, patient_id: int) -> None:
    allowed = visible_ids(user, session)
    if allowed is not None and patient_id not in allowed:
        raise HTTPException(404, "Gestante no encontrada.")


def secure_cookie() -> bool:
    return os.getenv("APP_ENV", "development") != "development"
