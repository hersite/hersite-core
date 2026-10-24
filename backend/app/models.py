from typing import Any, Optional
from sqlalchemy import Column, JSON
from sqlmodel import Field, SQLModel
from sqlalchemy import UniqueConstraint


class Gestante(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

    dni: Optional[str] = Field(default=None, index=True, unique=True)
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

    presion_basal_disponible: int = Field(default=1, nullable=False)
    embarazo_multiple: int = Field(default=0, nullable=False)
    antecedente_hemorragia: int = Field(default=0, nullable=False)

    presion_basal_sistolica: Optional[int] = None
    presion_basal_diastolica: Optional[int] = None
    activo: bool = Field(default=True)
    fecha_nacimiento: Optional[str] = None
    fecha_referencia_gestacion: Optional[str] = None
    actualizado_en: Optional[str] = None
    sync_key_hash: Optional[str] = None

class EvaluacionCentral(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

    server_id: str = Field(index=True, unique=True)
    id_local: str = Field(index=True, unique=True)

    gestante_id: Optional[int] = Field(default=None, foreign_key="gestante.id")
    perfil_id_local: int

    fecha_hora: str
    recibido_en: Optional[str] = None

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
    pin: str  # Hash PBKDF2; nunca se devuelve al cliente.
    rol: str = Field(default="medico") # Puede ser "medico" o "admin"
    activo: bool = True


class SesionWeb(SQLModel, table=True):
    token_hash: str = Field(primary_key=True)
    personal_id: int = Field(foreign_key="personalsalud.id", index=True)
    csrf_hash: str
    expira_en: int


class IntentoAcceso(SQLModel, table=True):
    clave: str = Field(primary_key=True)
    intentos: int = 0
    bloqueado_hasta: int = 0
    ventana_inicio: int = 0


class AccesoGestante(SQLModel, table=True):
    __table_args__ = (UniqueConstraint("personal_id", "gestante_id"),)
    id: Optional[int] = Field(default=None, primary_key=True)
    personal_id: int = Field(foreign_key="personalsalud.id", index=True)
    gestante_id: int = Field(foreign_key="gestante.id", index=True)


class VinculacionMovil(SQLModel, table=True):
    codigo_hash: str = Field(primary_key=True)
    gestante_id: int = Field(foreign_key="gestante.id", index=True)
    expira_en: int
