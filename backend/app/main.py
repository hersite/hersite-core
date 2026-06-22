from contextlib import asynccontextmanager
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select

from app.database import create_db_and_tables, get_session
from app.models import EvaluacionCentral, Gestante
from app.schemas import EvaluacionPayload, EvaluacionResponse, HealthResponse


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
        "dni": gestante.dni,
        "nombre": gestante.nombre,
        "celular": gestante.celular,
        "edad_materna": gestante.edad_materna,
        "semanas_gestacion": gestante.semanas_gestacion,
        "numero_embarazos": gestante.numero_embarazos,
        "cesarea_previa": gestante.cesarea_previa,
        "diabetes": gestante.diabetes,
        "hipertension_previa": gestante.hipertension_previa,
        "preeclampsia_previa": gestante.preeclampsia_previa,
        "anemia_gestacional": gestante.anemia_gestacional,
        "presion_basal_sistolica": gestante.presion_basal_sistolica,
        "presion_basal_diastolica": gestante.presion_basal_diastolica,
    }


def _evaluacion_to_card(evaluacion: EvaluacionCentral, gestante: Gestante | None):
    return {
        "id": evaluacion.id,
        "server_id": evaluacion.server_id,
        "id_local": evaluacion.id_local,
        "fecha_hora": evaluacion.fecha_hora,
        "nivel_riesgo": evaluacion.nivel_riesgo,
        "nivel_riesgo_legible": _riesgo_legible(evaluacion.nivel_riesgo),
        "mensaje": evaluacion.mensaje,
        "sintomas_detectados": evaluacion.sintomas_detectados,
        "total_sintomas": len(evaluacion.sintomas_detectados or []),
        "origen": evaluacion.origen,
        "estado_servidor": "recibido",
        "gestante": _gestante_to_dict(gestante),
    }


@app.get("/health", response_model=HealthResponse)
def health_check():
    return HealthResponse(
        status="ok",
        service="riesgo-materno-api",
    )

@app.get("/api/dashboard/resumen")
def dashboard_resumen(
    session: Session = Depends(get_session),
):
    gestantes = session.exec(select(Gestante)).all()
    evaluaciones = session.exec(select(EvaluacionCentral)).all()

    total_bajo = sum(1 for e in evaluaciones if e.nivel_riesgo == "Riesgo_Bajo")
    total_medio = sum(1 for e in evaluaciones if e.nivel_riesgo == "Riesgo_Medio")
    total_alto = sum(1 for e in evaluaciones if e.nivel_riesgo == "Riesgo_Alto")

    ultimas_evaluaciones = session.exec(
        select(EvaluacionCentral)
        .order_by(EvaluacionCentral.id.desc())
        .limit(5)
    ).all()

    ultimas_cards = []

    for evaluacion in ultimas_evaluaciones:
        gestante = None

        if evaluacion.gestante_id is not None:
            gestante = session.get(Gestante, evaluacion.gestante_id)

        ultimas_cards.append(
            _evaluacion_to_card(evaluacion, gestante)
        )

    return {
        "total_gestantes": len(gestantes),
        "total_evaluaciones": len(evaluaciones),
        "riesgos": {
            "bajo": total_bajo,
            "medio": total_medio,
            "alto": total_alto,
        },
        "ultimas_evaluaciones": ultimas_cards,
    }


@app.post("/api/evaluaciones", response_model=EvaluacionResponse)
def recibir_evaluacion(
    payload: EvaluacionPayload,
    session: Session = Depends(get_session),
):
    evaluacion_existente = session.exec(
        select(EvaluacionCentral).where(
            EvaluacionCentral.id_local == payload.id_local
        )
    ).first()

    if evaluacion_existente is not None:
        return EvaluacionResponse(
            ok=True,
            server_id=evaluacion_existente.server_id,
            message="La evaluación ya estaba registrada en el servidor.",
        )

    gestante_id = None

    if payload.perfil is not None and payload.perfil.dni:
        gestante = session.exec(
            select(Gestante).where(
                Gestante.dni == payload.perfil.dni
            )
        ).first()

        if gestante is None:
            gestante = Gestante(
                dni=payload.perfil.dni,
                nombre=payload.perfil.nombre,
                celular=payload.perfil.celular,
                edad_materna=payload.perfil.edad_materna,
                semanas_gestacion=payload.perfil.semanas_gestacion,
                numero_embarazos=payload.perfil.numero_embarazos,
                cesarea_previa=payload.perfil.cesarea_previa,
                diabetes=payload.perfil.diabetes,
                hipertension_previa=payload.perfil.hipertension_previa,
                preeclampsia_previa=payload.perfil.preeclampsia_previa,
                anemia_gestacional=payload.perfil.anemia_gestacional,
                presion_basal_sistolica=payload.perfil.presion_basal_sistolica,
                presion_basal_diastolica=payload.perfil.presion_basal_diastolica,
            )

            session.add(gestante)
            session.commit()
            session.refresh(gestante)
        else:
            gestante.nombre = payload.perfil.nombre
            gestante.celular = payload.perfil.celular
            gestante.edad_materna = payload.perfil.edad_materna
            gestante.semanas_gestacion = payload.perfil.semanas_gestacion
            gestante.numero_embarazos = payload.perfil.numero_embarazos
            gestante.cesarea_previa = payload.perfil.cesarea_previa
            gestante.diabetes = payload.perfil.diabetes
            gestante.hipertension_previa = payload.perfil.hipertension_previa
            gestante.preeclampsia_previa = payload.perfil.preeclampsia_previa
            gestante.anemia_gestacional = payload.perfil.anemia_gestacional
            gestante.presion_basal_sistolica = payload.perfil.presion_basal_sistolica
            gestante.presion_basal_diastolica = payload.perfil.presion_basal_diastolica

            session.add(gestante)
            session.commit()
            session.refresh(gestante)

        gestante_id = gestante.id

    server_id = f"srv_{uuid4()}"

    evaluacion = EvaluacionCentral(
        server_id=server_id,
        id_local=payload.id_local,
        gestante_id=gestante_id,
        perfil_id_local=payload.perfil_id_local,
        fecha_hora=payload.fecha_hora,
        form_data=payload.form_data,
        sintomas_detectados=payload.sintomas_detectados,
        nivel_riesgo=payload.nivel_riesgo,
        mensaje=payload.mensaje,
        probabilidades=payload.probabilidades,
        sync_status_local=payload.sync_status_local,
        origen=payload.origen,
    )

    session.add(evaluacion)
    session.commit()
    session.refresh(evaluacion)

    return EvaluacionResponse(
        ok=True,
        server_id=server_id,
        message="Evaluación registrada correctamente en el servidor.",
    )


@app.get("/api/evaluaciones")
def listar_evaluaciones(
    session: Session = Depends(get_session),
):
    evaluaciones = session.exec(
        select(EvaluacionCentral).order_by(EvaluacionCentral.id.desc())
    ).all()

    return evaluaciones

@app.get("/api/evaluaciones/ultimas")
def listar_ultimas_evaluaciones(
    limit: int = Query(default=20, ge=1, le=100),
    session: Session = Depends(get_session),
):
    evaluaciones = session.exec(
        select(EvaluacionCentral)
        .order_by(EvaluacionCentral.id.desc())
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
):
    evaluacion = session.get(EvaluacionCentral, evaluacion_id)

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
):
    gestantes = session.exec(
        select(Gestante).order_by(Gestante.id.desc())
    ).all()

    return gestantes


@app.get("/api/gestantes/{gestante_id}/evaluaciones")
def listar_evaluaciones_por_gestante(
    gestante_id: int,
    session: Session = Depends(get_session),
):
    gestante = session.get(Gestante, gestante_id)

    if gestante is None:
        raise HTTPException(
            status_code=404,
            detail="Gestante no encontrada.",
        )

    evaluaciones = session.exec(
        select(EvaluacionCentral)
        .where(EvaluacionCentral.gestante_id == gestante_id)
        .order_by(EvaluacionCentral.id.desc())
    ).all()

    return {
        "gestante": _gestante_to_dict(gestante),
        "total_evaluaciones": len(evaluaciones),
        "evaluaciones": [
            _evaluacion_to_card(evaluacion, gestante)
            for evaluacion in evaluaciones
        ],
    }