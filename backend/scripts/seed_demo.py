import sys
from datetime import datetime, timedelta
from pathlib import Path
from uuid import uuid4

from sqlmodel import Session, select

BACKEND_ROOT = Path(__file__).resolve().parents[1]

if str(BACKEND_ROOT) not in sys.path:
    sys.path.append(str(BACKEND_ROOT))

from app.database import create_db_and_tables, engine
from app.models import EvaluacionCentral, Gestante

def crear_form_data(
    *,
    edad_materna: int,
    semanas_gestacion: int,
    numero_embarazos: int,
    cesarea_previa: int,
    diabetes: int,
    hipertension_previa: int,
    preeclampsia_previa: int,
    anemia_gestacional: int,
    presion_basal_sistolica: int,
    presion_basal_diastolica: int,
    presion_sistolica: int,
    presion_diastolica: int,
    cefalea: int = 0,
    alteracion_visual: int = 0,
    zumbido: int = 0,
    dolor_hipocondrio: int = 0,
    dolor_boca_estomago: int = 0,
    hinchazon: int = 0,
    sangrado: int = 0,
    mareo: int = 0,
    sudoracion: int = 0,
    fiebre: int = 0,
    hipotermia: int = 0,
    flujo_fetido: int = 0,
    dolor_abdominal: int = 0,
    perdida_liquido: int = 0,
    confusion: int = 0,
    movimientos_disminuidos: int = 0,
    dificultad_respirar: int = 0,
    taquicardia: int = 0,
):
    return {
        "Edad_Materna": edad_materna,
        "Semanas_Gestacion": semanas_gestacion,
        "Numero_Embarazos": numero_embarazos,
        "Cesarea_Previa": cesarea_previa,
        "Diabetes": diabetes,
        "Hipertension_Previa": hipertension_previa,
        "Preeclampsia_Previa": preeclampsia_previa,
        "Anemia_Gestacional": anemia_gestacional,
        "Presion_Basal_Sistolica": presion_basal_sistolica,
        "Presion_Basal_Diastolica": presion_basal_diastolica,
        "Presion_Sistolica": presion_sistolica,
        "Presion_Diastolica": presion_diastolica,
        "Taquicardia_Sostenida": taquicardia,
        "Cefalea_Intensa": cefalea,
        "Alteracion_Visual": alteracion_visual,
        "Zumbido_Oidos": zumbido,
        "Dolor_Hipocondrio_Derecho": dolor_hipocondrio,
        "Dolor_Boca_Estomago": dolor_boca_estomago,
        "Hinchazon_Cara_Manos": hinchazon,
        "Sangrado_Vaginal": sangrado,
        "Mareo_Desmayo": mareo,
        "Sudoracion_Fria": sudoracion,
        "Fiebre_Escalofrios": fiebre,
        "Hipotermia_Subjetiva": hipotermia,
        "Flujo_Vaginal_Fetido": flujo_fetido,
        "Dolor_Abdominal_Bajo": dolor_abdominal,
        "Perdida_Liquido_Amniotico": perdida_liquido,
        "Confusion_Somnolencia": confusion,
        "Movimientos_Fetales_Disminuidos": movimientos_disminuidos,
        "Dificultad_Respirar": dificultad_respirar,
    }


def mensaje_por_riesgo(nivel_riesgo: str) -> str:
    if nivel_riesgo == "Riesgo_Alto":
        return (
            "Riesgo alto: se identifican signos de alarma. "
            "Acude de inmediato al establecimiento de salud más cercano."
        )

    if nivel_riesgo == "Riesgo_Medio":
        return (
            "Riesgo medio: se identifican síntomas o antecedentes que requieren seguimiento. "
            "Comunícate con el personal de salud y mantente atenta a nuevos signos de alarma."
        )

    return (
        "Riesgo bajo: no se identifican signos de alarma en este registro. "
        "Continúa con tus controles y vuelve a registrar síntomas si aparece alguna molestia."
    )


def probabilidades_por_riesgo(nivel_riesgo: str):
    if nivel_riesgo == "Riesgo_Alto":
        return [[0.03, 0.12, 0.85]]

    if nivel_riesgo == "Riesgo_Medio":
        return [[0.18, 0.72, 0.10]]

    return [[0.94, 0.05, 0.01]]


def sintomas_por_form_data(form_data: dict):
    etiquetas = {
        "Cefalea_Intensa": "Cefalea intensa",
        "Alteracion_Visual": "Alteración visual",
        "Zumbido_Oidos": "Zumbido de oídos",
        "Dolor_Hipocondrio_Derecho": "Dolor en hipocondrio derecho",
        "Dolor_Boca_Estomago": "Dolor en boca del estómago",
        "Hinchazon_Cara_Manos": "Hinchazón de cara/manos",
        "Sangrado_Vaginal": "Sangrado vaginal",
        "Mareo_Desmayo": "Mareo o desmayo",
        "Sudoracion_Fria": "Sudoración fría",
        "Fiebre_Escalofrios": "Fiebre o escalofríos",
        "Flujo_Vaginal_Fetido": "Flujo vaginal fétido",
        "Dolor_Abdominal_Bajo": "Dolor abdominal bajo",
        "Perdida_Liquido_Amniotico": "Pérdida de líquido amniótico",
        "Confusion_Somnolencia": "Confusión o somnolencia",
        "Movimientos_Fetales_Disminuidos": "Movimientos fetales disminuidos",
        "Dificultad_Respirar": "Dificultad para respirar",
        "Taquicardia_Sostenida": "Taquicardia sostenida",
    }

    sintomas = []

    for key, label in etiquetas.items():
        if form_data.get(key) == 1:
            sintomas.append(label)

    if form_data.get("Presion_Sistolica", 0) >= 140:
        sintomas.append("Presión sistólica elevada")

    if form_data.get("Presion_Diastolica", 0) >= 90:
        sintomas.append("Presión diastólica elevada")

    return sintomas


def insertar_o_actualizar_gestante(session: Session, data: dict):
    gestante = session.exec(
        select(Gestante).where(Gestante.dni == data["dni"])
    ).first()

    if gestante is None:
        gestante = Gestante(**data)
        session.add(gestante)
        session.commit()
        session.refresh(gestante)
        return gestante

    for key, value in data.items():
        setattr(gestante, key, value)

    session.add(gestante)
    session.commit()
    session.refresh(gestante)

    return gestante


def insertar_evaluacion_demo(
    session: Session,
    *,
    gestante: Gestante,
    perfil_id_local: int,
    fecha_hora: str,
    nivel_riesgo: str,
    form_data: dict,
    demo_key: str,
):
    server_id = f"demo_{demo_key}"

    existente = session.exec(
        select(EvaluacionCentral).where(EvaluacionCentral.server_id == server_id)
    ).first()

    if existente is not None:
        return False

    evaluacion = EvaluacionCentral(
        server_id=server_id,
        id_local=str(uuid4()),
        gestante_id=gestante.id,
        perfil_id_local=perfil_id_local,
        fecha_hora=fecha_hora,
        form_data=form_data,
        sintomas_detectados=sintomas_por_form_data(form_data),
        nivel_riesgo=nivel_riesgo,
        mensaje=mensaje_por_riesgo(nivel_riesgo),
        probabilidades=probabilidades_por_riesgo(nivel_riesgo),
        sync_status_local="pendiente",
        origen="seed_demo",
    )

    session.add(evaluacion)
    session.commit()

    return True


def main():
    create_db_and_tables()

    base_date = datetime.now()

    casos = [
        {
            "gestante": {
                "dni": "90000001",
                "nombre": "María Quispe Ramos",
                "celular": "999100001",
                "edad_materna": 19,
                "semanas_gestacion": 28,
                "numero_embarazos": 1,
                "cesarea_previa": 0,
                "diabetes": 0,
                "hipertension_previa": 0,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 110,
                "presion_basal_diastolica": 70,
            },
            "riesgo": "Riesgo_Bajo",
            "presion": (116, 76),
        },
        {
            "gestante": {
                "dni": "90000002",
                "nombre": "Rosa Huamán Flores",
                "celular": "999100002",
                "edad_materna": 24,
                "semanas_gestacion": 32,
                "numero_embarazos": 2,
                "cesarea_previa": 1,
                "diabetes": 0,
                "hipertension_previa": 0,
                "preeclampsia_previa": 1,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 115,
                "presion_basal_diastolica": 75,
            },
            "riesgo": "Riesgo_Medio",
            "presion": (132, 84),
            "cefalea": 1,
            "zumbido": 1,
        },
        {
            "gestante": {
                "dni": "90000003",
                "nombre": "Elena Condori Mamani",
                "celular": "999100003",
                "edad_materna": 31,
                "semanas_gestacion": 35,
                "numero_embarazos": 3,
                "cesarea_previa": 0,
                "diabetes": 1,
                "hipertension_previa": 1,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 120,
                "presion_basal_diastolica": 78,
            },
            "riesgo": "Riesgo_Alto",
            "presion": (152, 96),
            "cefalea": 1,
            "alteracion_visual": 1,
            "hinchazon": 1,
        },
        {
            "gestante": {
                "dni": "90000004",
                "nombre": "Juana Ccahuana Soto",
                "celular": "999100004",
                "edad_materna": 22,
                "semanas_gestacion": 24,
                "numero_embarazos": 1,
                "cesarea_previa": 0,
                "diabetes": 0,
                "hipertension_previa": 0,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 1,
                "presion_basal_sistolica": 108,
                "presion_basal_diastolica": 68,
            },
            "riesgo": "Riesgo_Medio",
            "presion": (118, 78),
            "mareo": 1,
        },
        {
            "gestante": {
                "dni": "90000005",
                "nombre": "Carmen Apaza Vera",
                "celular": "999100005",
                "edad_materna": 27,
                "semanas_gestacion": 37,
                "numero_embarazos": 2,
                "cesarea_previa": 1,
                "diabetes": 0,
                "hipertension_previa": 0,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 112,
                "presion_basal_diastolica": 72,
            },
            "riesgo": "Riesgo_Alto",
            "presion": (126, 82),
            "perdida_liquido": 1,
        },
        {
            "gestante": {
                "dni": "90000006",
                "nombre": "Lucía Poma Arias",
                "celular": "999100006",
                "edad_materna": 18,
                "semanas_gestacion": 20,
                "numero_embarazos": 1,
                "cesarea_previa": 0,
                "diabetes": 0,
                "hipertension_previa": 0,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 106,
                "presion_basal_diastolica": 66,
            },
            "riesgo": "Riesgo_Bajo",
            "presion": (110, 70),
        },
        {
            "gestante": {
                "dni": "90000007",
                "nombre": "Ana Salazar Medina",
                "celular": "999100007",
                "edad_materna": 35,
                "semanas_gestacion": 30,
                "numero_embarazos": 4,
                "cesarea_previa": 1,
                "diabetes": 1,
                "hipertension_previa": 0,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 118,
                "presion_basal_diastolica": 76,
            },
            "riesgo": "Riesgo_Medio",
            "presion": (136, 88),
            "dolor_boca_estomago": 1,
        },
        {
            "gestante": {
                "dni": "90000008",
                "nombre": "Teresa Choque Lima",
                "celular": "999100008",
                "edad_materna": 29,
                "semanas_gestacion": 34,
                "numero_embarazos": 2,
                "cesarea_previa": 0,
                "diabetes": 0,
                "hipertension_previa": 1,
                "preeclampsia_previa": 1,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 122,
                "presion_basal_diastolica": 80,
            },
            "riesgo": "Riesgo_Alto",
            "presion": (148, 94),
            "cefalea": 1,
            "dolor_hipocondrio": 1,
        },
        {
            "gestante": {
                "dni": "90000009",
                "nombre": "Patricia Rojas León",
                "celular": "999100009",
                "edad_materna": 26,
                "semanas_gestacion": 26,
                "numero_embarazos": 1,
                "cesarea_previa": 0,
                "diabetes": 0,
                "hipertension_previa": 0,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 109,
                "presion_basal_diastolica": 69,
            },
            "riesgo": "Riesgo_Bajo",
            "presion": (114, 74),
        },
        {
            "gestante": {
                "dni": "90000010",
                "nombre": "Milagros Yupanqui Torres",
                "celular": "999100010",
                "edad_materna": 33,
                "semanas_gestacion": 38,
                "numero_embarazos": 3,
                "cesarea_previa": 1,
                "diabetes": 0,
                "hipertension_previa": 0,
                "preeclampsia_previa": 0,
                "anemia_gestacional": 0,
                "presion_basal_sistolica": 114,
                "presion_basal_diastolica": 73,
            },
            "riesgo": "Riesgo_Alto",
            "presion": (122, 80),
            "sangrado": 1,
        },
    ]

    insertadas = 0

    with Session(engine) as session:
        for index, caso in enumerate(casos, start=1):
            gestante = insertar_o_actualizar_gestante(session, caso["gestante"])

            presion_sistolica, presion_diastolica = caso["presion"]

            form_data = crear_form_data(
                edad_materna=caso["gestante"]["edad_materna"],
                semanas_gestacion=caso["gestante"]["semanas_gestacion"],
                numero_embarazos=caso["gestante"]["numero_embarazos"],
                cesarea_previa=caso["gestante"]["cesarea_previa"],
                diabetes=caso["gestante"]["diabetes"],
                hipertension_previa=caso["gestante"]["hipertension_previa"],
                preeclampsia_previa=caso["gestante"]["preeclampsia_previa"],
                anemia_gestacional=caso["gestante"]["anemia_gestacional"],
                presion_basal_sistolica=caso["gestante"]["presion_basal_sistolica"],
                presion_basal_diastolica=caso["gestante"]["presion_basal_diastolica"],
                presion_sistolica=presion_sistolica,
                presion_diastolica=presion_diastolica,
                cefalea=caso.get("cefalea", 0),
                alteracion_visual=caso.get("alteracion_visual", 0),
                zumbido=caso.get("zumbido", 0),
                dolor_hipocondrio=caso.get("dolor_hipocondrio", 0),
                dolor_boca_estomago=caso.get("dolor_boca_estomago", 0),
                hinchazon=caso.get("hinchazon", 0),
                sangrado=caso.get("sangrado", 0),
                mareo=caso.get("mareo", 0),
                sudoracion=caso.get("sudoracion", 0),
                fiebre=caso.get("fiebre", 0),
                hipotermia=caso.get("hipotermia", 0),
                flujo_fetido=caso.get("flujo_fetido", 0),
                dolor_abdominal=caso.get("dolor_abdominal", 0),
                perdida_liquido=caso.get("perdida_liquido", 0),
                confusion=caso.get("confusion", 0),
                movimientos_disminuidos=caso.get("movimientos_disminuidos", 0),
                dificultad_respirar=caso.get("dificultad_respirar", 0),
                taquicardia=caso.get("taquicardia", 0),
            )

            fecha = base_date - timedelta(days=(10 - index) * 4)

            creada = insertar_evaluacion_demo(
                session,
                gestante=gestante,
                perfil_id_local=100 + index,
                fecha_hora=fecha.isoformat(),
                nivel_riesgo=caso["riesgo"],
                form_data=form_data,
                demo_key=f"{caso['gestante']['dni']}_{index}",
            )

            if creada:
                insertadas += 1

    print("Seed demo finalizado.")
    print(f"Evaluaciones demo insertadas: {insertadas}")
    print("Si aparece 0, probablemente ya habías ejecutado el seed antes.")


if __name__ == "__main__":
    main()