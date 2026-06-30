from typing import Any, Optional

from pydantic import BaseModel


class PerfilPayload(BaseModel):
    dni: Optional[str] = None
    nombre: Optional[str] = None
    celular: Optional[str] = None

    edad_materna: Optional[int] = None
    semanas_gestacion: Optional[int] = None
    numero_embarazos: Optional[int] = None

    cesarea_previa: Optional[int] = None
    diabetes: Optional[int] = None
    hipertension_previa: Optional[int] = None
    preeclampsia_previa: Optional[int] = None
    anemia_gestacional: Optional[int] = None

    presion_basal_disponible: int = 1
    embarazo_multiple: int = 0
    antecedente_hemorragia: int = 0

    presion_basal_sistolica: Optional[int] = None
    presion_basal_diastolica: Optional[int] = None


class EvaluacionPayload(BaseModel):
    id_local: str
    perfil_id_local: int
    fecha_hora: str

    form_data: dict[str, Any]
    sintomas_detectados: list[str]

    nivel_riesgo: str
    mensaje: str
    probabilidades: Optional[Any] = None

    sync_status_local: Optional[str] = None
    origen: Optional[str] = None

    perfil: Optional[PerfilPayload] = None


class EvaluacionResponse(BaseModel):
    ok: bool
    server_id: str
    message: str


class HealthResponse(BaseModel):
    status: str
    service: str
