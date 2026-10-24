"""Alta local explícita de personal, sin endpoint público ni PIN predefinido."""
import getpass
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from sqlmodel import Session, select
from app.database import create_db_and_tables, engine
from app.models import PersonalSalud
from app.security import hash_password


def main():
    dni = input("DNI del profesional (8 números): ").strip()
    nombre = input("Nombre: ").strip()
    rol = input("Rol (admin/medico): ").strip()
    pin = getpass.getpass("PIN de 6 números: ")
    confirmation = getpass.getpass("Repite el PIN: ")
    if not re.fullmatch(r"[0-9]{8}", dni) or len(nombre) < 2 or rol not in {"admin", "medico"}:
        raise SystemExit("Datos de personal inválidos.")
    if not re.fullmatch(r"[0-9]{6}", pin) or pin != confirmation:
        raise SystemExit("Los PIN deben tener 6 números y coincidir.")
    create_db_and_tables()
    with Session(engine) as session:
        if session.exec(select(PersonalSalud).where(PersonalSalud.dni == dni)).first():
            raise SystemExit("Ese DNI ya tiene una cuenta. No se sobrescribió.")
        session.add(PersonalSalud(dni=dni, nombre=nombre, rol=rol, pin=hash_password(pin)))
        session.commit()
    print("Cuenta de personal creada.")


if __name__ == "__main__":
    main()
