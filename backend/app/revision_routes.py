"""Registro explícito de revisión, independiente de la clasificación clínica."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import EvaluacionCentral, PersonalSalud, RevisionEvaluacion
from app.security import current_user, require_patient

router = APIRouter()


def datos_revision(session: Session, evaluacion_id: int) -> dict:
    revision = session.get(RevisionEvaluacion, evaluacion_id)
    return {
        "estado_revision": "revisada" if revision else "por_revisar",
        "revisado_en": revision.revisado_en if revision else None,
        "revisado_por": revision.profesional_nombre if revision else None,
    }


@router.post("/api/evaluaciones/{evaluacion_id}/revision")
def marcar_revisada(evaluacion_id: int, session: Session = Depends(get_session),
                    user: PersonalSalud = Depends(current_user)):
    evaluacion = session.exec(select(EvaluacionCentral).where(
        EvaluacionCentral.id == evaluacion_id).with_for_update()).first()
    if evaluacion is None or evaluacion.gestante_id is None:
        raise HTTPException(404, "Evaluación no encontrada.")
    require_patient(user, session, evaluacion.gestante_id)
    if session.get(RevisionEvaluacion, evaluacion_id) is None:
        session.add(RevisionEvaluacion(evaluacion_id=evaluacion_id, personal_id=user.id,
                    profesional_nombre=user.nombre,
                    revisado_en=datetime.now(timezone.utc).isoformat()))
        session.commit()
    return {"ok": True, "evaluacion_id": evaluacion_id,
            **datos_revision(session, evaluacion_id)}
