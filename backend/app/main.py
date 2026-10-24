import os
from collections import Counter
from contextlib import asynccontextmanager
from datetime import datetime, date, timedelta, timezone
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import IntegrityError
from app.auth_routes import router as auth_router, mobile_patient
from app.security import current_user, require_admin, require_patient, visible_ids
from app.models import PersonalSalud
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select

from app.database import create_db_and_tables, get_session
from app.models import EvaluacionCentral, Gestante
from app.schemas import EvaluacionPayload, EvaluacionResponse, HealthResponse, PerfilPayload



@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield


app = FastAPI(
    title="Riesgo Materno API",
    description="Backend central para sincronización de evaluaciones de riesgo materno.",
    version="0.1.0",
    lifespan=lifespan,
)


app.include_router(auth_router)


@app.middleware("http")
async def transport_security(request: Request, call_next):
    local_hosts = {"localhost", "127.0.0.1", "10.0.2.2", "testserver", "::1"}
    development = os.getenv("APP_ENV", "development") == "development"
    if request.url.scheme != "https" and not (development and request.url.hostname in local_hosts):
        return JSONResponse(status_code=400, content={"detail": "Esta API requiere HTTPS."})
    response = await call_next(request)
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Content-Type-Options"] = "nosniff"
    return response


@app.exception_handler(RequestValidationError)
async def invalid_payload(request, error):
    # No devolver PIN, claves de sincronización ni el formulario clínico.
    return JSONResponse(status_code=422, content={"detail": [
        {"loc": list(item["loc"]), "msg": item["msg"], "type": item["type"]}
        for item in error.errors()
    ]})


def _visible_query(model, user, session):
    query = select(model)
    allowed = visible_ids(user, session)
    if allowed is not None:
        column = Gestante.id if model is Gestante else EvaluacionCentral.gestante_id
        query = query.where(column.in_(allowed))
    return query


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _riesgo_legible(nivel_riesgo: str) -> str:
    if nivel_riesgo == "Riesgo_Alto":
        return "Riesgo alto"
    if nivel_riesgo == "Riesgo_Medio":
        return "Riesgo medio"
    if nivel_riesgo == "Riesgo_Bajo":
        return "Riesgo bajo"
    return nivel_riesgo


def _gestante_to_dict(gestante: Gestante | None):
    if gestante is None:
        return None

    return {
        "id": gestante.id,
        "activo": gestante.activo,
        "dni": gestante.dni,
        "nombre": gestante.nombre,
        "celular": gestante.celular,
        "edad_materna": _edad_actual(gestante),
        "semanas_gestacion": _semanas_actuales(gestante),
        "numero_embarazos": gestante.numero_embarazos,
        "cesarea_previa": gestante.cesarea_previa,
        "diabetes": gestante.diabetes,
        "hipertension_previa": gestante.hipertension_previa,
        "preeclampsia_previa": gestante.preeclampsia_previa,
        "anemia_gestacional": gestante.anemia_gestacional,
        "presion_basal_disponible": gestante.presion_basal_disponible,
        "embarazo_multiple": gestante.embarazo_multiple,
        "antecedente_hemorragia": gestante.antecedente_hemorragia,
        "presion_basal_sistolica": gestante.presion_basal_sistolica,
        "presion_basal_diastolica": gestante.presion_basal_diastolica,
        "fecha_nacimiento": gestante.fecha_nacimiento,
        "fecha_referencia_gestacion": gestante.fecha_referencia_gestacion,
    }


def _edad_actual(gestante):
    if not gestante.fecha_nacimiento:
        return gestante.edad_materna
    born = date.fromisoformat(gestante.fecha_nacimiento)
    today = datetime.now(timezone(timedelta(hours=-5))).date()
    return today.year - born.year - ((today.month, today.day) < (born.month, born.day))


def _semanas_actuales(gestante):
    if not gestante.fecha_referencia_gestacion or gestante.semanas_gestacion is None:
        return gestante.semanas_gestacion
    today = datetime.now(timezone(timedelta(hours=-5))).date()
    days = max((today - date.fromisoformat(gestante.fecha_referencia_gestacion)).days, 0)
    return gestante.semanas_gestacion + days // 7


def _evaluacion_to_card(evaluacion: EvaluacionCentral, gestante: Gestante | None):
    return {
        "id": evaluacion.id,
        "server_id": evaluacion.server_id,
        "id_local": evaluacion.id_local,
        "fecha_hora": evaluacion.fecha_hora,
        "recibido_en": evaluacion.recibido_en,
        "probabilidades": evaluacion.probabilidades,
        "semanas_gestacion": (evaluacion.form_data or {}).get("Semanas_Gestacion"),
        "nivel_riesgo": evaluacion.nivel_riesgo,
        "nivel_riesgo_legible": _riesgo_legible(evaluacion.nivel_riesgo),
        "mensaje": evaluacion.mensaje,
        "sintomas_detectados": evaluacion.sintomas_detectados,
        "total_sintomas": len(evaluacion.sintomas_detectados or []),
        "origen": evaluacion.origen,
        "estado_servidor": "recibido",
        "gestante": _gestante_to_dict(gestante),
    }

def _parse_fecha_iso(fecha_hora: str):
    try:
        value = datetime.fromisoformat(fecha_hora.replace("Z", "+00:00"))
        lima = timezone(timedelta(hours=-5))
        if value.tzinfo is None:
            value = value.replace(tzinfo=lima)
        return value.astimezone(lima)
    except Exception:
        return None


def _mes_corto(numero_mes: int) -> str:
    meses = {
        1: "Ene",
        2: "Feb",
        3: "Mar",
        4: "Abr",
        5: "May",
        6: "Jun",
        7: "Jul",
        8: "Ago",
        9: "Sep",
        10: "Oct",
        11: "Nov",
        12: "Dic",
    }

    return meses.get(numero_mes, "S/F")


def _detectar_factores_clinicos(form_data: dict):
    factores = []

    presion_sistolica = form_data.get("Presion_Sistolica")
    presion_diastolica = form_data.get("Presion_Diastolica")

    if isinstance(presion_sistolica, int | float) and presion_sistolica >= 140:
        factores.append("Presión sistólica elevada")

    if isinstance(presion_diastolica, int | float) and presion_diastolica >= 90:
        factores.append("Presión diastólica elevada")

    if form_data.get("Cefalea_Intensa") == 1:
        factores.append("Cefalea intensa")

    if form_data.get("Alteracion_Visual") == 1:
        factores.append("Alteración visual")

    if form_data.get("Zumbido_Oidos") == 1:
        factores.append("Zumbido de oídos")

    if form_data.get("Dolor_Hipocondrio_Derecho") == 1:
        factores.append("Dolor en hipocondrio derecho")

    if form_data.get("Dolor_Boca_Estomago") == 1:
        factores.append("Dolor en boca del estómago")

    if form_data.get("Hinchazon_Cara_Manos") == 1:
        factores.append("Hinchazón de cara/manos")

    if form_data.get("Sangrado_Vaginal") in [1, "1", "Leve", "Abundante"]:
        factores.append("Sangrado vaginal")

    if form_data.get("Perdida_Liquido_Amniotico") == 1:
        factores.append("Pérdida de líquido amniótico")

    if form_data.get("Movimientos_Fetales_Disminuidos") == 1:
        factores.append("Movimientos fetales disminuidos")

    if form_data.get("Fiebre_Escalofrios") == 1:
        factores.append("Fiebre o escalofríos")

    if form_data.get("Flujo_Vaginal_Fetido") == 1:
        factores.append("Flujo vaginal fétido")

    if form_data.get("Dificultad_Respirar") == 1:
        factores.append("Dificultad para respirar")

    if form_data.get("Confusion_Somnolencia") == 1:
        factores.append("Confusión o somnolencia")

    if form_data.get("Diabetes") == 1:
        factores.append("Antecedente de diabetes")

    if form_data.get("Hipertension_Previa") == 1:
        factores.append("Hipertensión previa")

    if form_data.get("Preeclampsia_Previa") == 1:
        factores.append("Preeclampsia previa")

    if form_data.get("Anemia_Gestacional") == 1:
        factores.append("Anemia gestacional")

    if form_data.get("Cesarea_Previa") == 1:
        factores.append("Cesárea previa")

    if form_data.get("Embarazo_Multiple") == 1:
        factores.append("Embarazo múltiple")

    if form_data.get("Antecedente_Hemorragia") == 1:
        factores.append("Antecedente de hemorragia")

    return factores

@app.get("/health", response_model=HealthResponse)
def health_check():
    return HealthResponse(
        status="ok",
        service="riesgo-materno-api",
    )

@app.get("/api/dashboard/resumen")
def dashboard_resumen(
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
    # 1. Obtenemos todas las gestantes, ordenadas por registro reciente
    gestantes = session.exec(_visible_query(Gestante, user, session).order_by(Gestante.id.desc())).all()
    evaluaciones = session.exec(_visible_query(EvaluacionCentral, user, session)).all()

    # 2. Resumen de riesgos (basado en evaluaciones totales)
    total_bajo = sum(1 for e in evaluaciones if e.nivel_riesgo == "Riesgo_Bajo")
    total_medio = sum(1 for e in evaluaciones if e.nivel_riesgo == "Riesgo_Medio")
    total_alto = sum(1 for e in evaluaciones if e.nivel_riesgo == "Riesgo_Alto")
    
    # 3. Construimos la lista de gestantes con su última evaluación (si tiene)
    gestantes_cards = []
    for g in gestantes:
        # Buscamos la última evaluación de esta gestante específica
        ultima_eval = session.exec(
            select(EvaluacionCentral)
            .where(EvaluacionCentral.gestante_id == g.id)
            .order_by(EvaluacionCentral.fecha_hora.desc(), EvaluacionCentral.id.desc())
            .limit(1)
        ).first()

        gestantes_cards.append({
            "gestante": _gestante_to_dict(g),
            "ultima_evaluacion": _evaluacion_to_card(ultima_eval, g) if ultima_eval else None
        })

    return {
        "total_gestantes": len(gestantes),
        "total_evaluaciones": len(evaluaciones),
        "riesgos": {
            "bajo": total_bajo,
            "medio": total_medio,
            "alto": total_alto,
        },
        "ultimas_gestantes": gestantes_cards, # Ahora enviamos gestantes, no solo evaluaciones
    }
   
@app.get("/api/tendencias/resumen")
def tendencias_resumen(
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
    gestantes = session.exec(_visible_query(Gestante, user, session)).all()
    evaluaciones = session.exec(_visible_query(EvaluacionCentral, user, session)).all()

    total_evaluaciones = len(evaluaciones)

    riesgos = {
        "bajo": 0,
        "medio": 0,
        "alto": 0,
    }

    tendencia_por_mes = {}
    contador_factores = Counter()

    for evaluacion in evaluaciones:
        if evaluacion.nivel_riesgo == "Riesgo_Bajo":
            riesgos["bajo"] += 1
        elif evaluacion.nivel_riesgo == "Riesgo_Medio":
            riesgos["medio"] += 1
        elif evaluacion.nivel_riesgo == "Riesgo_Alto":
            riesgos["alto"] += 1

        fecha = _parse_fecha_iso(evaluacion.fecha_hora)

        if fecha is not None:
            key = fecha.strftime("%Y-%m")
            label = f"{_mes_corto(fecha.month)} {fecha.year}"
        else:
            key = "sin-fecha"
            label = "Sin fecha"

        if key not in tendencia_por_mes:
            tendencia_por_mes[key] = {
                "key": key,
                "mes": label,
                "bajo": 0,
                "medio": 0,
                "alto": 0,
                "total": 0,
            }

        tendencia_por_mes[key]["total"] += 1

        if evaluacion.nivel_riesgo == "Riesgo_Bajo":
            tendencia_por_mes[key]["bajo"] += 1
        elif evaluacion.nivel_riesgo == "Riesgo_Medio":
            tendencia_por_mes[key]["medio"] += 1
        elif evaluacion.nivel_riesgo == "Riesgo_Alto":
            tendencia_por_mes[key]["alto"] += 1

        factores = _detectar_factores_clinicos(evaluacion.form_data or {})

        for factor in factores:
            contador_factores[factor] += 1

    tendencia_mensual = sorted(
        tendencia_por_mes.values(),
        key=lambda item: item["key"],
    )

    factores_frecuentes = []

    for factor, total in contador_factores.most_common(8):
        porcentaje = 0

        if total_evaluaciones > 0:
            porcentaje = round((total / total_evaluaciones) * 100, 1)

        factores_frecuentes.append(
            {
                "factor": factor,
                "total": total,
                "porcentaje": porcentaje,
            }
        )

    riesgo_predominante = "Sin datos"

    if total_evaluaciones > 0:
        riesgo_predominante = max(
            riesgos,
            key=lambda key: riesgos[key],
        )

    return {
        "total_gestantes": len(gestantes),
        "total_evaluaciones": total_evaluaciones,
        "riesgos": riesgos,
        "riesgo_predominante": riesgo_predominante,
        "tendencia_mensual": tendencia_mensual,
        "factores_frecuentes": factores_frecuentes,
    }

@app.get("/api/sistema/estado")
def sistema_estado(
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
# 1. Filtramos solo a las pacientes activas
    gestantes_activas = session.exec(_visible_query(Gestante, user, session).where(Gestante.activo == True)).all()
    
    total_bajo = 0
    total_medio = 0
    total_alto = 0
    total_evaluaciones = 0

    # 2. Contamos SOLO la última evaluación de las activas
    for g in gestantes_activas:
        ultima_eval = session.exec(
            select(EvaluacionCentral)
            .where(EvaluacionCentral.gestante_id == g.id)
            .order_by(EvaluacionCentral.fecha_hora.desc(), EvaluacionCentral.id.desc())
            .limit(1)
        ).first()

        if ultima_eval:
            total_evaluaciones += 1
            if ultima_eval.nivel_riesgo == "Riesgo_Bajo":
                total_bajo += 1
            elif ultima_eval.nivel_riesgo == "Riesgo_Medio":
                total_medio += 1
            elif ultima_eval.nivel_riesgo == "Riesgo_Alto":
                total_alto += 1

    # 3. Obtenemos la última evaluación global para la card
    ultima_evaluacion = session.exec(
        _visible_query(EvaluacionCentral, user, session)
        .order_by(EvaluacionCentral.fecha_hora.desc(), EvaluacionCentral.id.desc())
        .limit(1)
    ).first()

    ultima_card = None
    if ultima_evaluacion is not None:
        gestante = None
        if ultima_evaluacion.gestante_id is not None:
            gestante = session.get(Gestante, ultima_evaluacion.gestante_id)
        ultima_card = _evaluacion_to_card(ultima_evaluacion, gestante)

    return {
        "api": {
            "status": "online",
            "service": "riesgo-materno-api",
            "version": "0.1.0",
            "timestamp": datetime.now().isoformat(),
        },
        "database": {
            "status": "conectado",
            "motor": os.getenv("DATABASE_ENGINE", "SQLite"),
            "modo": os.getenv("DATABASE_MODE", "desarrollo"),
            "archivo": "riesgo_materno_db" if os.getenv("DATABASE_ENGINE") == "PostgreSQL" else "riesgo_materno_central.db",
            "migracion_pendiente": "Ninguna" if os.getenv("DATABASE_ENGINE") == "PostgreSQL" else "PostgreSQL",
        },
        "mobile": {
            "origen": "flutter_offline",
            "modelo": "LightGBM v3.2 embebido en ONNX",
            "features_modelo": 34,
            "almacenamiento_local": "SQLite + SQLCipher",
            "sincronizacion": "automática por conectividad",
        },
        "web": {
            "framework": "React + Vite",
            "estado": "conectado a FastAPI",
        },
        "resumen": {
            "total_gestantes": len(gestantes_activas),
            "total_evaluaciones": total_evaluaciones,
            "riesgos": {
                "bajo": total_bajo,
                "medio": total_medio,
                "alto": total_alto, # ¡Ahora sí mandará el número exacto!
            },
            "ultima_evaluacion": ultima_card,
        },
        "endpoints": [
            {
                "method": "GET",
                "path": "/health",
                "descripcion": "Verifica si la API está activa.",
            },
            {
                "method": "POST",
                "path": "/api/evaluaciones",
                "descripcion": "Recibe evaluaciones sincronizadas desde Flutter.",
            },
            {
                "method": "GET",
                "path": "/api/dashboard/resumen",
                "descripcion": "Resumen principal para el dashboard web.",
            },
            {
                "method": "GET",
                "path": "/api/evaluaciones/ultimas",
                "descripcion": "Lista resumida de últimas evaluaciones.",
            },
            {
                "method": "GET",
                "path": "/api/gestantes",
                "descripcion": "Lista de gestantes registradas en backend.",
            },
            {
                "method": "GET",
                "path": "/api/tendencias/resumen",
                "descripcion": "Indicadores poblacionales y factores frecuentes.",
            },
            {
                "method": "GET",
                "path": "/api/sistema/estado",
                "descripcion": "Estado técnico del sistema.",
            },
        ],
    }

def _update_profile(gestante, payload):
    values = payload.model_dump(mode="json")
    # Una evaluación histórica no debe sobrescribir el perfil vigente.
    if gestante.actualizado_en and (not values.get("actualizado_en") or values["actualizado_en"] < gestante.actualizado_en):
        raise HTTPException(409, "Hay una versión más reciente de este perfil en el servidor. Solicita revisar los datos antes de sobrescribirlos.")
    for key, value in values.items():
        setattr(gestante, key, value)


@app.post("/api/evaluaciones", response_model=EvaluacionResponse)
def recibir_evaluacion(payload: EvaluacionPayload, patient: Gestante = Depends(mobile_patient),
                       session: Session = Depends(get_session)):
    if payload.perfil.dni != patient.dni:
        raise HTTPException(403, "La evaluación no pertenece a esta cuenta.")
    local_id = str(payload.id_local)
    existing = session.exec(select(EvaluacionCentral).where(EvaluacionCentral.id_local == local_id)).first()
    if existing:
        if existing.gestante_id != patient.id:
            raise HTTPException(409, "El identificador de evaluación ya está en uso.")
        return EvaluacionResponse(ok=True, server_id=existing.server_id, message="Evaluación ya registrada.")
    values = payload.model_dump(mode="json", exclude={"perfil"})
    evaluation = EvaluacionCentral(**values, server_id=f"srv_{uuid4()}", gestante_id=patient.id,
                                  recibido_en=datetime.now().astimezone().isoformat())
    session.add(evaluation)
    # Los cambios de perfil se sincronizan por separado; una evaluación conserva su instantánea.
    try:
        session.commit()
        session.refresh(evaluation)
    except IntegrityError:
        session.rollback()
        existing = session.exec(select(EvaluacionCentral).where(EvaluacionCentral.id_local == local_id)).first()
        if existing and existing.gestante_id == patient.id:
            return EvaluacionResponse(ok=True, server_id=existing.server_id, message="Evaluación ya registrada.")
        raise HTTPException(409, "No se pudo registrar la evaluación sin duplicar datos.")
    return EvaluacionResponse(ok=True, server_id=evaluation.server_id, message="Evaluación recibida.")


@app.get("/api/evaluaciones")
def listar_evaluaciones(
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
    evaluaciones = session.exec(
        _visible_query(EvaluacionCentral, user, session).order_by(EvaluacionCentral.fecha_hora.desc(), EvaluacionCentral.id.desc())
    ).all()

    return evaluaciones

@app.get("/api/evaluaciones/ultimas")
def listar_ultimas_evaluaciones(
    limit: int = Query(default=20, ge=1, le=100),
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
    evaluaciones = session.exec(
        _visible_query(EvaluacionCentral, user, session)
        .order_by(EvaluacionCentral.fecha_hora.desc(), EvaluacionCentral.id.desc())
        .limit(limit)
    ).all()

    resultado = []

    for evaluacion in evaluaciones:
        gestante = None

        if evaluacion.gestante_id is not None:
            gestante = session.get(Gestante, evaluacion.gestante_id)

        resultado.append(
            _evaluacion_to_card(evaluacion, gestante)
        )

    return resultado


@app.get("/api/evaluaciones/{evaluacion_id}")
def obtener_detalle_evaluacion(
    evaluacion_id: int,
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
    evaluacion = session.get(EvaluacionCentral, evaluacion_id)
    if evaluacion is not None:
        require_patient(user, session, evaluacion.gestante_id)

    if evaluacion is None:
        raise HTTPException(
            status_code=404,
            detail="Evaluación no encontrada.",
        )

    gestante = None

    if evaluacion.gestante_id is not None:
        gestante = session.get(Gestante, evaluacion.gestante_id)

    return {
        **_evaluacion_to_card(evaluacion, gestante),
        "perfil_id_local": evaluacion.perfil_id_local,
        "form_data": evaluacion.form_data,
        "probabilidades": evaluacion.probabilidades,
        "sync_status_local": evaluacion.sync_status_local,
    }

@app.get("/api/gestantes")
def listar_gestantes(
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
# Quitamos el filtro .where(Gestante.activo == True) para traer todas
    gestantes = session.exec(
        _visible_query(Gestante, user, session).order_by(Gestante.id.desc())
    ).all()
    return [_gestante_to_dict(g) for g in gestantes]


@app.get("/api/gestantes/{gestante_id}/evaluaciones")
def listar_evaluaciones_por_gestante(
    gestante_id: int,
    session: Session = Depends(get_session),
    user: PersonalSalud = Depends(current_user),
):
    require_patient(user, session, gestante_id)
    gestante = session.get(Gestante, gestante_id)

    if gestante is None:
        raise HTTPException(
            status_code=404,
            detail="Gestante no encontrada.",
        )

    evaluaciones = session.exec(
        select(EvaluacionCentral)
        .where(EvaluacionCentral.gestante_id == gestante_id)
        .order_by(EvaluacionCentral.fecha_hora.desc(), EvaluacionCentral.id.desc())
    ).all()

    return {
        "gestante": _gestante_to_dict(gestante),
        "total_evaluaciones": len(evaluaciones),
        "evaluaciones": [
            _evaluacion_to_card(evaluacion, gestante)
            for evaluacion in evaluaciones
        ],
    }

@app.post("/api/perfiles")
def registrar_perfil(perfil: PerfilPayload, patient: Gestante = Depends(mobile_patient),
                     session: Session = Depends(get_session)):
    if perfil.dni != patient.dni:
        raise HTTPException(403, "No puedes modificar otra cuenta.")
    _update_profile(patient, perfil)
    session.add(patient)
    session.commit()
    return {"ok": True, "server_id": str(patient.id), "message": "Perfil recibido."}


@app.put("/api/gestantes/{gestante_id}/alta")
def dar_de_alta_gestante(gestante_id: int, session: Session = Depends(get_session),
                         user: PersonalSalud = Depends(require_admin)):
    # Buscamos a la gestante
    gestante = session.get(Gestante, gestante_id)
    
    if not gestante:
        raise HTTPException(status_code=404, detail="Gestante no encontrada")
    
    # Marcamos como inactiva (Asegúrate de que tu modelo Gestante tenga el campo 'estado' o 'activo')
    # Si no tienes un campo 'estado', deberías agregarlo a tu archivo app/models.py
    gestante.activo = False 
    
    session.add(gestante)
    session.commit()
    session.refresh(gestante)
    
    return {"mensaje": "Gestante dada de alta exitosamente"}
