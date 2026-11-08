"""Regresión de revisiones usando exclusivamente SQLite en memoria."""
import time
import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient
from sqlalchemy.pool import StaticPool
from sqlmodel import SQLModel, Session, create_engine, select

from app.database import get_session
from app.main import app
from app.models import (AccesoGestante, EvaluacionCentral, Gestante, PersonalSalud,
                        RevisionEvaluacion, SesionWeb)
from app.security import COOKIE_NAME, digest


class RevisionTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine('sqlite://', connect_args={'check_same_thread': False},
                                    poolclass=StaticPool)
        SQLModel.metadata.create_all(self.engine)
        with Session(self.engine) as db:
            db.add_all([
                Gestante(id=1, dni='12345678', nombre='Prueba'),
                Gestante(id=2, dni='87654321', nombre='Otra prueba'),
                PersonalSalud(id=1, dni='11111111', nombre='Profesional Prueba', pin='unused'),
                PersonalSalud(id=2, dni='22222222', nombre='Sin acceso', pin='unused'),
                PersonalSalud(id=3, dni='33333333', nombre='Administración', pin='unused', rol='admin'),
            ])
            db.commit()
            db.add(AccesoGestante(personal_id=1, gestante_id=1))
            for i in [1, 2]:
                db.add(EvaluacionCentral(id=i, server_id=f'srv_{i}', id_local=f'local-{i}',
                    gestante_id=i, perfil_id_local=1, fecha_hora=f'2026-11-0{i}T12:00:00+00:00',
                    recibido_en='2026-11-07T12:00:00+00:00', form_data={},
                    sintomas_detectados=[], nivel_riesgo='Riesgo_Alto', mensaje='Prueba'))
            for i in [1, 2, 3]:
                db.add(SesionWeb(token_hash=digest(f'token-{i}'), personal_id=i,
                    csrf_hash=digest('csrf'), expira_en=int(time.time()) + 600))
            db.commit()

        def session():
            with Session(self.engine) as db:
                yield db
        self.previous = app.dependency_overrides.copy()
        app.dependency_overrides[get_session] = session
        self.client = TestClient(app, base_url='https://testserver')

    def tearDown(self):
        self.client.close()
        app.dependency_overrides.clear()
        app.dependency_overrides.update(self.previous)
        self.engine.dispose()

    def web(self, usuario=1, csrf=True):
        return {'Cookie': f'{COOKIE_NAME}=token-{usuario}',
                **({'X-CSRF-Token': 'csrf'} if csrf else {})}

    def test_reading_card_does_not_mark_reviewed(self):
        self.assertEqual(self.client.get('/api/version').json(),
                         {'version': '1.1.0', 'revision_evaluaciones': True})
        data = self.client.get('/api/evaluaciones/1', headers=self.web()).json()
        self.assertEqual(data['estado_revision'], 'por_revisar')
        self.assertIsNone(data['revisado_en'])
        with Session(self.engine) as db:
            self.assertIsNone(db.get(RevisionEvaluacion, 1))

    def test_explicit_review_is_persistent_idempotent_and_does_not_change_risk(self):
        first = self.client.post('/api/evaluaciones/1/revision', headers=self.web())
        self.assertEqual(first.status_code, 200, first.text)
        data = first.json()
        self.assertEqual(data['revisado_por'], 'Profesional Prueba')
        again = self.client.post('/api/evaluaciones/1/revision', headers=self.web(3))
        self.assertEqual(again.json(), data)
        with Session(self.engine) as db:
            self.assertEqual(len(db.exec(select(RevisionEvaluacion)).all()), 1)
            self.assertEqual(db.get(RevisionEvaluacion, 1).personal_id, 1)
            self.assertEqual(db.get(EvaluacionCentral, 1).nivel_riesgo, 'Riesgo_Alto')
        resumen = self.client.get('/api/dashboard/resumen', headers=self.web()).json()
        self.assertEqual(resumen['ultimas_gestantes'][0]['ultima_evaluacion']['estado_revision'], 'revisada')

    def test_csrf_auth_and_patient_permissions_are_enforced(self):
        path = '/api/evaluaciones/1/revision'
        self.assertEqual(self.client.post(path).status_code, 401)
        self.assertEqual(self.client.post(path, headers=self.web(csrf=False)).status_code, 403)
        self.assertEqual(self.client.post(path, headers=self.web(2)).status_code, 404)
        self.assertEqual(self.client.post('/api/evaluaciones/999/revision', headers=self.web()).status_code, 404)

    def test_new_evaluation_does_not_inherit_previous_review(self):
        self.client.post('/api/evaluaciones/1/revision', headers=self.web())
        with Session(self.engine) as db:
            db.add(EvaluacionCentral(id=3, server_id='srv_new', id_local='new', gestante_id=1,
                perfil_id_local=1, fecha_hora='2026-11-07T15:00:00+00:00', form_data={},
                sintomas_detectados=[], nivel_riesgo='Riesgo_Alto', mensaje='Nueva prueba'))
            db.commit()
        resumen = self.client.get('/api/dashboard/resumen', headers=self.web()).json()
        nueva = resumen['ultimas_gestantes'][0]['ultima_evaluacion']
        self.assertEqual(nueva['id'], 3)
        self.assertEqual(nueva['estado_revision'], 'por_revisar')
        self.assertEqual(self.client.get('/api/evaluaciones/1', headers=self.web()).json()['estado_revision'], 'revisada')

    def test_additive_creation_keeps_existing_evaluations(self):
        with self.engine.begin() as conn:
            RevisionEvaluacion.__table__.drop(conn)
        with patch('app.database.engine', self.engine):
            from app.database import create_db_and_tables
            create_db_and_tables()
        with Session(self.engine) as db:
            self.assertEqual(len(db.exec(select(EvaluacionCentral)).all()), 2)
            self.assertEqual(db.exec(select(RevisionEvaluacion)).all(), [])

    def resumen_activo(self, usuario=1):
        response = self.client.get('/api/sistema/estado', headers=self.web(usuario))
        self.assertEqual(response.status_code, 200, response.text)
        return response.json()['resumen']

    def test_pending_counter_decreases_on_review_without_changing_high_risk(self):
        self.assertEqual(self.resumen_activo()['total_por_revisar'], 1)
        self.assertEqual(self.resumen_activo(3)['total_por_revisar'], 2)
        self.client.post('/api/evaluaciones/1/revision', headers=self.web())
        resumen = self.resumen_activo()
        self.assertEqual(resumen['total_por_revisar'], 0)
        self.assertEqual(resumen['riesgos']['alto'], 1)
        self.assertEqual(resumen['total_evaluaciones'], 1)

    def test_pending_counter_ignores_older_evaluations_and_counts_each_patient_once(self):
        self.client.post('/api/evaluaciones/1/revision', headers=self.web())
        with Session(self.engine) as db:
            db.add(EvaluacionCentral(id=3, server_id='srv_old', id_local='old', gestante_id=1,
                perfil_id_local=1, fecha_hora='2026-10-01T12:00:00+00:00', form_data={},
                sintomas_detectados=[], nivel_riesgo='Riesgo_Alto', mensaje='Anterior'))
            db.commit()
        self.assertEqual(self.resumen_activo()['total_por_revisar'], 0)
        with Session(self.engine) as db:
            for i in [4, 5]:
                db.add(EvaluacionCentral(id=i, server_id=f'srv_new_{i}', id_local=f'new-{i}',
                    gestante_id=1, perfil_id_local=1, fecha_hora='2026-11-08T12:00:00+00:00',
                    form_data={}, sintomas_detectados=[], nivel_riesgo='Riesgo_Alto', mensaje='Nueva'))
            db.commit()
        self.assertEqual(self.resumen_activo()['total_por_revisar'], 1)
        self.client.post('/api/evaluaciones/5/revision', headers=self.web())
        self.assertEqual(self.resumen_activo()['total_por_revisar'], 0)

    def test_pending_counter_excludes_inactive_unassigned_and_patients_without_evaluations(self):
        with Session(self.engine) as db:
            db.add_all([Gestante(id=3, dni='90000003', activo=False),
                        Gestante(id=4, dni='90000004')])
            db.commit()
            db.add_all([AccesoGestante(personal_id=1, gestante_id=3),
                        AccesoGestante(personal_id=1, gestante_id=4)])
            db.add(EvaluacionCentral(id=3, server_id='srv_inactive', id_local='inactive',
                gestante_id=3, perfil_id_local=1, fecha_hora='2026-11-08T12:00:00+00:00',
                form_data={}, sintomas_detectados=[], nivel_riesgo='Riesgo_Alto', mensaje='Inactiva'))
            db.commit()
        resumen = self.resumen_activo()
        self.assertEqual(resumen['total_gestantes'], 2)
        self.assertEqual(resumen['total_por_revisar'], 1)
        self.assertEqual(self.resumen_activo(3)['total_por_revisar'], 2)
        self.assertEqual(self.resumen_activo(2)['total_por_revisar'], 0)
