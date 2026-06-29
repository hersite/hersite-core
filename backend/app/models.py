from typing import Any, Optional
from sqlalchemy import Column, JSON
from sqlmodel import Field, SQLModel


class Gestante(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

    dni: Optional[str] = Field(default=None, index=True)
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

    presion_basal_sistolica: Optional[int] = None
    presion_basal_diastolica: Optional[int] = None
    activo: bool = Field(default=True)

class EvaluacionCentral(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

    server_id: str = Field(index=True)
    id_local: str = Field(index=True)

    gestante_id: Optional[int] = Field(default=None, foreign_key="gestante.id")
    perfil_id_local: int

    fecha_hora: str

    form_data: dict[str, Any] = Field(
        default_factory=dict,
        sa_column=Column(JSON),
    )

    sintomas_detectados: list[str] = Field(
        default_factory=list,
        sa_column=Column(JSON),
    )

    nivel_riesgo: str
    mensaje: str

    probabilidades: Optional[Any] = Field(
        default=None,
        sa_column=Column(JSON),
    )

    sync_status_local: Optional[str] = None
    origen: Optional[str] = None

class PersonalSalud(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    dni: str = Field(unique=True, index=True)
    nombre: str
    pin: str  # PIN de acceso (6 dígitos)
    rol: str = Field(default="medico") # Puede ser "medico" o "admin"
    activo: bool = True