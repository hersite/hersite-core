from datetime import date, datetime, timezone, timedelta
from typing import Annotated, Any, Literal
from uuid import UUID
import math

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

Flag = Annotated[int, Field(strict=True, ge=0, le=1)]
Dni = Annotated[str, Field(pattern=r"^[0-9]{8}$")]
Pin = Annotated[str, Field(pattern=r"^[0-9]{6}$")]


def canonical_datetime(value: str) -> str:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    # Los registros antiguos de la app eran horas de Lima sin offset.
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone(timedelta(hours=-5)))
    if parsed > datetime.now(timezone.utc) + timedelta(minutes=10):
        raise ValueError("La fecha no puede estar en el futuro.")
    return parsed.astimezone(timezone.utc).isoformat(timespec="microseconds")


class PerfilPayload(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    dni: Dni
    nombre: str = Field(min_length=2, max_length=150)
    celular: str = Field(pattern=r"^[0-9]{9}$")
    edad_materna: int = Field(strict=True, ge=12, le=120)
    semanas_gestacion: int = Field(strict=True, ge=1, le=60)
    numero_embarazos: int = Field(strict=True, ge=1, le=100)
    cesarea_previa: Flag
    diabetes: Flag
    hipertension_previa: Flag
    preeclampsia_previa: Flag
    anemia_gestacional: Flag
    presion_basal_disponible: Flag
    embarazo_multiple: Flag
    antecedente_hemorragia: Flag
    presion_basal_sistolica: int = Field(strict=True)
    presion_basal_diastolica: int = Field(strict=True)
    fecha_nacimiento: date | None = None
    fecha_referencia_gestacion: date | None = None
    actualizado_en: str | None = None

    @field_validator("nombre")
    @classmethod
    def nombre_valido(cls, value):
        if not any(c.isalpha() for c in value) or any(not (c.isalpha() or c.isspace() or c in ".'’-" ) for c in value):
            raise ValueError("El nombre debe contener letras, sin números ni símbolos.")
        return value

    @field_validator("actualizado_en")
    @classmethod
    def fecha_actualizacion(cls, value):
        return canonical_datetime(value) if value is not None else None

    @model_validator(mode="after")
    def validar_coherencia(self):
        today = datetime.now(timezone(timedelta(hours=-5))).date()
        if self.fecha_nacimiento and self.fecha_nacimiento > today:
            raise ValueError("La fecha de nacimiento no puede ser futura.")
        if self.fecha_nacimiento:
            born = self.fecha_nacimiento
            age = today.year - born.year - ((today.month, today.day) < (born.month, born.day))
            if age != self.edad_materna:
                raise ValueError("La edad no coincide con la fecha de nacimiento.")
        if self.fecha_referencia_gestacion and self.fecha_referencia_gestacion > today:
            raise ValueError("La fecha de referencia no puede ser futura.")
        if self.presion_basal_disponible:
            if not (80 <= self.presion_basal_sistolica <= 180 and 40 <= self.presion_basal_diastolica <= 120
                    and self.presion_basal_diastolica < self.presion_basal_sistolica):
                raise ValueError("La presión basal no es válida.")
        elif self.presion_basal_sistolica != -1 or self.presion_basal_diastolica != -1:
            raise ValueError("La presión no disponible debe enviarse como -1.")
        return self


class EvaluacionPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id_local: UUID
    perfil_id_local: int = Field(strict=True, gt=0)
    fecha_hora: str
    form_data: dict[str, Any]
    sintomas_detectados: list[Annotated[str, Field(max_length=150)]] = Field(max_length=30)
    nivel_riesgo: Literal["Riesgo_Bajo", "Riesgo_Medio", "Riesgo_Alto"]
    mensaje: str = Field(min_length=1, max_length=2000)
    probabilidades: list[float] | None = None
    sync_status_local: Literal["pendiente", "sincronizado"] | None = None
    origen: Literal["flutter_offline"] | None = None
    perfil: PerfilPayload

    @field_validator("fecha_hora")
    @classmethod
    def validar_fecha(cls, value):
        return canonical_datetime(value)

    @field_validator("probabilidades", mode="before")
    @classmethod
    def probabilidades_validas(cls, value):
        if value is None:
            return None
        if isinstance(value, list) and len(value) == 1 and isinstance(value[0], list):
            value = value[0]
        if not isinstance(value, list) or len(value) != 3 or any(
            isinstance(p, bool) or not isinstance(p, (int, float)) or not math.isfinite(p) or not 0 <= p <= 1
            for p in value
        ) or abs(sum(value) - 1) > 0.02:
            raise ValueError("Se requieren tres probabilidades válidas cuya suma sea 1.")
        return value

    @field_validator("form_data")
    @classmethod
    def validar_formulario(cls, value):
        # Solo se validan los datos: no se cambian reglas ni predicciones clínicas.
        flags = ["Cesarea_Previa", "Diabetes", "Hipertension_Previa", "Preeclampsia_Previa",
                 "Anemia_Gestacional", "Embarazo_Multiple", "Antecedente_Hemorragia",
                 "Taquicardia_Sostenida", "Cefalea_Intensa", "Alteracion_Visual", "Zumbido_Oidos",
                 "Dolor_Hipocondrio_Derecho", "Dolor_Boca_Estomago", "Hinchazon_Cara_Manos",
                 "Mareo_Desmayo", "Sudoracion_Fria", "Fiebre_Escalofrios", "Hipotermia_Subjetiva",
                 "Flujo_Vaginal_Fetido", "Dolor_Abdominal_Bajo", "Perdida_Liquido_Amniotico",
                 "Confusion_Somnolencia", "Movimientos_Fetales_Disminuidos", "Dificultad_Respirar",
                 "Presion_Basal_Disponible", "Presion_Actual_Disponible"]
        ranges = {**{k: (0, 1) for k in flags}, "Edad_Materna": (12, 120),
                  "Semanas_Gestacion": (1, 60), "Numero_Embarazos": (1, 100), "Sangrado_Vaginal": (0, 2)}
        for key, (low, high) in ranges.items():
            number = value.get(key)
            if type(number) not in (int, float) or not math.isfinite(number) or not low <= number <= high or int(number) != number:
                raise ValueError(f"Campo inválido: {key}.")
        for prefix, available, low, high in [("Presion_Basal_", "Presion_Basal_Disponible", 80, 180),
                                             ("Presion_", "Presion_Actual_Disponible", 70, 250)]:
            sys, dia = value.get(prefix + "Sistolica"), value.get(prefix + "Diastolica")
            if type(sys) not in (int, float) or type(dia) not in (int, float):
                raise ValueError("La presión debe ser numérica.")
            if not math.isfinite(sys) or not math.isfinite(dia) or int(sys) != sys or int(dia) != dia:
                raise ValueError("La presión debe contener números enteros finitos.")
            if value[available] == 0:
                if sys != -1 or dia != -1:
                    raise ValueError("La presión no disponible debe enviarse como -1.")
            elif not (math.isfinite(sys) and math.isfinite(dia) and low <= sys <= high and
                      40 <= dia <= (120 if prefix == "Presion_Basal_" else 160) and dia < sys):
                raise ValueError("Presión fuera del rango admitido por el formulario.")
        return value


class LoginPayload(BaseModel):
    dni: Dni
    pin: Pin


class CambiarPinPayload(BaseModel):
    actual: Pin
    nueva: Pin


class VerificadorPin(BaseModel):
    model_config = ConfigDict(extra="forbid")
    hash: str = Field(pattern=r"^pbkdf2_sha256\$600000\$[A-Za-z0-9_-]{43}=$")
    salt: str = Field(pattern=r"^[A-Za-z0-9_-]{43}=$")


class RegistroMovilPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")
    perfil: PerfilPayload
    sync_key: str = Field(pattern=r"^[A-Za-z0-9_-]{43}$")
    codigo_vinculacion: str | None = Field(default=None, min_length=20, max_length=100)
    recovery_pin: VerificadorPin | None = None


class RecuperarCuentaPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")
    dni: Dni
    pin: Pin


class ConfirmarRecuperacionPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")
    token: str = Field(pattern=r"^[A-Za-z0-9_-]{43}$")
    sync_key: str = Field(pattern=r"^[A-Za-z0-9_-]{43}$")


class CambiarPinMovilPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")
    actual: Pin
    nuevo: VerificadorPin


class RecordatorioRespaldo(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    respaldo_id: UUID
    tipo: Literal["pastilla", "cita"]
    titulo: str = Field(min_length=1, max_length=150)
    fecha_hora: datetime
    repeticion: Literal["unaVez", "diaria"]
    completado: bool = Field(strict=True)


class RespaldoRecordatoriosPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")
    base_version: int = Field(strict=True, ge=0)
    registros: list[RecordatorioRespaldo] = Field(max_length=2000)

    @model_validator(mode="after")
    def claves_unicas(self):
        if len({r.respaldo_id for r in self.registros}) != len(self.registros):
            raise ValueError("Hay recordatorios repetidos.")
        return self


class EvaluacionResponse(BaseModel):
    ok: bool
    server_id: str
    message: str


class HealthResponse(BaseModel):
    status: str
    service: str
