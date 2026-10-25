"""Pruebas aisladas: nunca conectan a PostgreSQL ni a la VM."""
import base64
import hashlib
import secrets
import time
import unittest
from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.pool import StaticPool
from sqlalchemy import inspect, text
from sqlmodel import SQLModel, Session, create_engine, select

from app.auth_routes import router
from app.database import get_session
from app.models import Gestante, EvaluacionCentral, RecuperacionMovil
from app.security import digest


def verifier(pin):
    salt = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode()
    value = base64.urlsafe_b64encode(hashlib.pbkdf2_hmac(
        'sha256', pin.encode(), salt.encode(), 600_000)).decode()
    return {'hash': f'pbkdf2_sha256$600000${value}', 'salt': salt}


PROFILE = dict(dni='12345678', nombre='Ana Prueba', celular='999888777', edad_materna=25,
               semanas_gestacion=20, numero_embarazos=1, cesarea_previa=0, diabetes=0,
               hipertension_previa=0, preeclampsia_previa=0, anemia_gestacional=0,
               presion_basal_disponible=0, embarazo_multiple=0, antecedente_hemorragia=0,
               presion_basal_sistolica=-1, presion_basal_diastolica=-1)


class RecoveryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pin = verifier('123456')
        cls.other_pin = verifier('654321')

    def setUp(self):
        self.engine = create_engine('sqlite://', connect_args={'check_same_thread': False},
                                    poolclass=StaticPool)
        SQLModel.metadata.create_all(self.engine)
        app = FastAPI()
        app.include_router(router)
        self.app = app

        def session():
            with Session(self.engine) as db:
                yield db

        app.dependency_overrides[get_session] = session
        self.client = TestClient(app)
        self.key = secrets.token_urlsafe(32)
        self.register()

    def tearDown(self):
        self.client.close()
        self.engine.dispose()

    def register(self, key=None, pin=None, profile=None):
        return self.client.post('/api/mobile/registro', json={
            'perfil': profile or PROFILE, 'sync_key': key or self.key,
            'recovery_pin': pin or self.pin})

    def recover(self, pin='123456', dni='12345678'):
        return self.client.post('/api/mobile/recuperar', json={'dni': dni, 'pin': pin})

    def confirm(self, token, key):
        return self.client.post('/api/mobile/confirmar-recuperacion',
                                json={'token': token, 'sync_key': key})

    def backup(self, records, version=0, key=None, dni='12345678'):
        return self.client.post('/api/mobile/recordatorios',
            headers={'Authorization': f'Bearer {key or self.key}', 'X-Profile-DNI': dni},
            json={'base_version': version, 'registros': records})

    def test_recovers_only_authenticated_account_and_no_secrets(self):
        response = self.recover()
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data['perfil']['dni'], PROFILE['dni'])
        self.assertEqual(data['recordatorios'], {'version': 0, 'registros': []})
        self.assertEqual(response.headers['cache-control'], 'no-store')
        for name in ('sync_key_hash', 'recovery_pin_hash', 'recovery_pin_salt', '123456'):
            self.assertNotIn(name, response.text.replace('12345678', 'DNI'))

    def test_wrong_pin_and_unknown_dni_do_not_expose_account(self):
        first = self.recover('000000')
        second = self.recover('000000', '00000000')
        self.assertEqual(first.status_code, 401)
        self.assertEqual(first.json(), second.json())

    def test_five_attempts_lock_account_even_from_another_ip(self):
        for _ in range(5):
            self.assertEqual(self.recover('000000').status_code, 401)
        with TestClient(self.app, client=('another-ip', 54321)) as other_client:
            response = other_client.post('/api/mobile/recuperar',
                json={'dni': PROFILE['dni'], 'pin': '123456'})
            self.assertEqual(response.status_code, 429)

    def test_same_dni_new_key_does_not_replace_pin_or_profile(self):
        result = self.register(key=secrets.token_urlsafe(32), pin=self.other_pin,
                               profile={**PROFILE, 'nombre': 'Otro Nombre'})
        self.assertEqual(result.status_code, 409)
        self.assertEqual(self.recover('654321').status_code, 401)
        self.assertEqual(self.recover().json()['perfil']['nombre'], PROFILE['nombre'])

    def test_enrollment_never_overwrites_existing_pin(self):
        self.assertEqual(self.register(pin=self.other_pin).status_code, 200)
        self.assertEqual(self.recover('654321').status_code, 401)
        self.assertEqual(self.recover().status_code, 200)

    def test_legacy_account_requires_its_original_device_to_enable_recovery(self):
        with Session(self.engine) as db:
            patient = db.exec(select(Gestante)).one()
            patient.recovery_pin_hash = None
            patient.recovery_pin_salt = None
            db.add(patient)
            db.commit()
        self.assertEqual(self.recover().status_code, 401)
        self.assertEqual(self.register(key=secrets.token_urlsafe(32)).status_code, 409)
        self.assertEqual(self.register().status_code, 200)
        self.assertEqual(self.recover().status_code, 200)

    def test_preview_does_not_revoke_old_phone_and_confirmation_is_idempotent(self):
        token = self.recover().json()['token']
        self.assertEqual(self.backup([]).status_code, 200)
        key = secrets.token_urlsafe(32)
        self.assertEqual(self.confirm(token, key).status_code, 200)
        self.assertEqual(self.confirm(token, key).status_code, 200)
        self.assertEqual(self.confirm(token, secrets.token_urlsafe(32)).status_code, 401)
        self.assertEqual(self.backup([]).status_code, 401)
        self.assertEqual(self.backup([], key=key).status_code, 200)

    def test_ticket_expires(self):
        token = self.recover().json()['token']
        with Session(self.engine) as db:
            ticket = db.get(RecuperacionMovil, digest(token))
            ticket.expira_en = int(time.time()) - 1
            db.add(ticket)
            db.commit()
        self.assertEqual(self.confirm(token, secrets.token_urlsafe(32)).status_code, 401)

    def test_backups_keep_completed_and_deleted_records_and_prevent_stale_writes(self):
        record = dict(respaldo_id='e7991e00-5fa0-4ae1-ad63-06477e2d85ba', tipo='pastilla',
                      titulo='Pastilla de prueba', fecha_hora='2026-10-26T08:00:00',
                      repeticion='diaria', completado=False)
        response = self.backup([record])
        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(response.json()['version'], 1)
        self.assertEqual(self.backup([record]).json()['version'], 1)
        self.assertEqual(self.backup([{**record, 'completado': True}]).status_code, 409)
        self.assertEqual(self.backup([{**record, 'completado': True}], 1).status_code, 200)
        self.assertTrue(self.recover().json()['recordatorios']['registros'][0]['completado'])
        self.assertEqual(self.backup([], 2).status_code, 200)
        self.assertEqual(self.recover().json()['recordatorios']['registros'], [])
        self.assertEqual(self.backup([record], 1).status_code, 409)

    def test_backup_does_not_accept_another_accounts_credentials(self):
        other_key = secrets.token_urlsafe(32)
        self.assertEqual(self.register(key=other_key, profile={**PROFILE, 'dni': '87654321'}).status_code, 200)
        self.assertEqual(self.backup([], key=other_key).status_code, 401)
        self.assertEqual(self.backup([], key=other_key, dni='87654321').status_code, 200)

    def test_pin_change_updates_recovery_and_invalidates_tickets(self):
        token = self.recover().json()['token']
        headers = {'Authorization': f'Bearer {self.key}', 'X-Profile-DNI': PROFILE['dni']}
        invalid = self.client.post('/api/mobile/cambiar-pin', headers=headers,
                                   json={'actual': '000000', 'nuevo': self.other_pin})
        self.assertEqual(invalid.status_code, 401)
        response = self.client.post('/api/mobile/cambiar-pin', headers=headers,
                                    json={'actual': '123456', 'nuevo': self.other_pin})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.recover().status_code, 401)
        self.assertEqual(self.recover('654321').status_code, 200)
        self.assertEqual(self.confirm(token, secrets.token_urlsafe(32)).status_code, 401)

    def test_full_history_is_returned_in_chronological_order(self):
        with Session(self.engine) as db:
            patient = db.exec(select(Gestante)).one()
            for i, date in enumerate(['2026-01-01', '2026-02-01']):
                db.add(EvaluacionCentral(server_id=f'server-{i}', id_local=f'eval-{i}',
                    gestante_id=patient.id, perfil_id_local=99, fecha_hora=date,
                    form_data={'Semanas_Gestacion': 10 + i}, sintomas_detectados=[],
                    nivel_riesgo='Riesgo_Bajo', mensaje='Prueba', probabilidades=[1, 0, 0]))
            db.commit()
        data = self.recover().json()['evaluaciones']
        self.assertEqual(len(data), 2)
        self.assertEqual(data[0]['id_local'], 'eval-1')

    def test_additive_migration_preserves_existing_account(self):
        with self.engine.begin() as conn:
            conn.execute(text('ALTER TABLE gestante DROP COLUMN recovery_pin_hash'))
            conn.execute(text('ALTER TABLE gestante DROP COLUMN recovery_pin_salt'))
        with patch('app.database.engine', self.engine):
            from app.database import create_db_and_tables
            create_db_and_tables()
        names = {c['name'] for c in inspect(self.engine).get_columns('gestante')}
        self.assertTrue({'recovery_pin_hash', 'recovery_pin_salt'} <= names)
        with Session(self.engine) as db:
            self.assertEqual(len(db.exec(select(Gestante)).all()), 1)

    def test_real_application_routes_tls_and_validation_without_live_database(self):
        from app.main import app

        def db_session():
            with Session(self.engine) as db:
                yield db

        previous = app.dependency_overrides.copy()
        app.dependency_overrides[get_session] = db_session
        try:
            with patch('app.database.engine', self.engine):
                with TestClient(app, base_url='https://testserver') as client:
                    self.assertEqual(client.get('/health').json()['status'], 'ok')
                    recovered = client.post('/api/mobile/recuperar',
                        json={'dni': PROFILE['dni'], 'pin': '123456'})
                    self.assertEqual(recovered.status_code, 200)
                    invalid = client.post('/api/mobile/recuperar',
                        json={'dni': PROFILE['dni'], 'pin': 'NO-ECHO-SECRET'})
                    self.assertEqual(invalid.status_code, 422)
                    self.assertNotIn('NO-ECHO-SECRET', invalid.text)
                with TestClient(app, base_url='http://public.example') as client:
                    self.assertEqual(client.get('/health').status_code, 400)
        finally:
            app.dependency_overrides.clear()
            app.dependency_overrides.update(previous)


if __name__ == '__main__':
    unittest.main()
