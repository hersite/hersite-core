"""Regresión de la espera de despliegue, sin red ni esperas reales."""
import importlib.util
from pathlib import Path
import unittest
from urllib.error import HTTPError, URLError

script = Path(__file__).resolve().parents[2] / 'deploy' / 'esperar_servicio.py'
spec = importlib.util.spec_from_file_location('esperar_servicio', script)
readiness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(readiness)

HEALTH = {'status': 'ok', 'service': 'riesgo-materno-api'}
VERSION = {'version': '1.1.0', 'revision_evaluaciones': True}


class FakeClock:
    def __init__(self):
        self.time = 0

    def now(self):
        return self.time

    def sleep(self, seconds):
        self.time += seconds


class ReadinessTests(unittest.TestCase):
    def esperar(self, fetch, clock, version='1.1.0', timeout=180):
        readiness.esperar_servicio('https://test.invalid', version, timeout,
            fetch=fetch, clock=clock.now, pause=clock.sleep, report=lambda _: None)

    def test_backend_ready_after_twenty_seconds_is_not_rolled_back(self):
        clock = FakeClock()

        def fetch(url, timeout):
            if clock.time < 20:
                raise HTTPError(url, 502, 'Starting', {}, None)
            return VERSION if url.endswith('/api/version') else HEALTH

        self.esperar(fetch, clock)
        self.assertEqual(clock.time, 20)

    def test_connection_refused_and_503_are_retried(self):
        clock = FakeClock()

        def fetch(url, timeout):
            if clock.time == 0:
                raise URLError('refused')
            if clock.time < 6:
                raise HTTPError(url, 503, 'Starting', {}, None)
            return VERSION if url.endswith('/api/version') else HEALTH

        self.esperar(fetch, clock)
        self.assertEqual(clock.time, 6)

    def test_healthy_old_version_does_not_publish_new_panel(self):
        clock = FakeClock()
        with self.assertRaises(TimeoutError):
            self.esperar(lambda url, timeout: HEALTH if url.endswith('/health') else
                         {'version': '0.1.0'}, clock, timeout=8)
        self.assertEqual(clock.time, 8)

    def test_wrong_health_service_is_not_accepted(self):
        clock = FakeClock()
        with self.assertRaises(TimeoutError):
            self.esperar(lambda url, timeout: {'status': 'ok', 'service': 'other'},
                         clock, timeout=4)
        self.assertEqual(clock.time, 4)

    def test_permanent_failure_stops_at_deadline(self):
        clock = FakeClock()

        def fetch(url, timeout):
            raise URLError('unavailable')

        with self.assertRaises(TimeoutError):
            self.esperar(fetch, clock, timeout=9)
        self.assertEqual(clock.time, 9)

    def test_rollback_checks_health_without_requiring_new_version(self):
        clock = FakeClock()
        calls = []

        def fetch(url, timeout):
            calls.append(url)
            return HEALTH

        self.esperar(fetch, clock, version=None)
        self.assertEqual(calls, ['https://test.invalid/health'])
