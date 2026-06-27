from sqlmodel import Session, select

from app.database import create_db_and_tables, engine
from app.models import EvaluacionCentral, Gestante


DEMO_DNIS = {
    "90000001",
    "90000002",
    "90000003",
    "90000004",
    "90000005",
    "90000006",
    "90000007",
    "90000008",
    "90000009",
    "90000010",
}


def main():
    create_db_and_tables()

    evaluaciones_eliminadas = 0
    gestantes_eliminadas = 0
    gestantes_conservadas = 0

    with Session(engine) as session:
        evaluaciones = session.exec(
            select(EvaluacionCentral)
        ).all()

        for evaluacion in evaluaciones:
            es_demo_por_origen = evaluacion.origen == "seed_demo"
            es_demo_por_server_id = str(evaluacion.server_id).startswith("demo_")

            if es_demo_por_origen or es_demo_por_server_id:
                session.delete(evaluacion)
                evaluaciones_eliminadas += 1

        session.commit()

        for dni in DEMO_DNIS:
            gestante = session.exec(
                select(Gestante).where(Gestante.dni == dni)
            ).first()

            if gestante is None:
                continue

            evaluaciones_restantes = session.exec(
                select(EvaluacionCentral).where(
                    EvaluacionCentral.gestante_id == gestante.id
                )
            ).all()

            if evaluaciones_restantes:
                gestantes_conservadas += 1
                continue

            session.delete(gestante)
            gestantes_eliminadas += 1

        session.commit()

    print("Limpieza de datos demo finalizada.")
    print(f"Evaluaciones demo eliminadas: {evaluaciones_eliminadas}")
    print(f"Gestantes demo eliminadas: {gestantes_eliminadas}")
    print(f"Gestantes demo conservadas por tener evaluaciones no demo: {gestantes_conservadas}")
    print("Las evaluaciones reales sincronizadas desde Flutter no fueron eliminadas.")


if __name__ == "__main__":
    main()