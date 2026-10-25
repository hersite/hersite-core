import os

from dotenv import load_dotenv
from sqlmodel import SQLModel, Session, create_engine
from sqlalchemy import inspect, text
from pathlib import Path
from datetime import datetime, timezone, timedelta

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./riesgo_materno_central.db",
)

connect_args = {}

if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    DATABASE_URL,
    echo=False,
    connect_args=connect_args,
)


def create_db_and_tables() -> None:
    SQLModel.metadata.create_all(engine)
    # Actualización aditiva de instalaciones existentes: no elimina registros.
    additions = {
        "gestante": {"fecha_nacimiento": "TEXT", "fecha_referencia_gestacion": "TEXT",
                     "actualizado_en": "TEXT", "sync_key_hash": "TEXT",
                     "recovery_pin_hash": "TEXT", "recovery_pin_salt": "TEXT"},
        "evaluacioncentral": {"recibido_en": "TEXT"},
    }
    with engine.begin() as connection:
        inspector = inspect(connection)
        for table, columns in additions.items():
            existing = {column["name"] for column in inspector.get_columns(table)}
            for name, kind in columns.items():
                if name not in existing:
                    connection.execute(text(f'ALTER TABLE {table} ADD COLUMN {name} {kind}'))
        for table, column in [("gestante", "dni"), ("evaluacioncentral", "id_local"),
                              ("evaluacioncentral", "server_id")]:
            duplicates = connection.execute(text(
                f'SELECT {column} FROM {table} WHERE {column} IS NOT NULL '
                f'GROUP BY {column} HAVING COUNT(*) > 1 LIMIT 1'
            )).first()
            if duplicates:
                raise RuntimeError(f"Hay duplicados en {table}.{column}. Deben revisarse sin borrar datos automáticamente.")
            connection.execute(text(f'CREATE UNIQUE INDEX IF NOT EXISTS uq_{table}_{column} ON {table} ({column})'))
        # Orden cronológico uniforme para registros antiguos enviados sin offset.
        for row in connection.execute(text('SELECT id, fecha_hora FROM evaluacioncentral')).mappings().all():
            try:
                value = datetime.fromisoformat(row["fecha_hora"].replace("Z", "+00:00"))
                if value.tzinfo is None:
                    value = value.replace(tzinfo=timezone(timedelta(hours=-5)))
                normalized = value.astimezone(timezone.utc).isoformat(timespec="microseconds")
                if normalized != row["fecha_hora"]:
                    connection.execute(text('UPDATE evaluacioncentral SET fecha_hora=:fecha WHERE id=:id'),
                                       {"fecha": normalized, "id": row["id"]})
            except (TypeError, ValueError):
                raise RuntimeError("Hay evaluaciones con fechas inválidas. Revisa esos registros antes de actualizar.")
        # PINs legados: se conserva el mismo PIN, pero solo su derivación en disco.
        from app.security import hash_password
        for row in connection.execute(text('SELECT id, pin FROM personalsalud')).mappings().all():
            if not row["pin"].startswith("pbkdf2_sha256$"):
                connection.execute(text('UPDATE personalsalud SET pin=:pin WHERE id=:id'),
                                   {"pin": hash_password(row["pin"]), "id": row["id"]})


def get_session():
    with Session(engine) as session:
        yield session
