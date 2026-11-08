import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { enmascararDni } from '../src/utils/privacidad.js';

test('DNI: solo revela los dos primeros dígitos, incluidos ceros iniciales', () => {
  assert.equal(enmascararDni('12345678'), '12XXXXXX');
  assert.equal(enmascararDni('09342204'), '09XXXXXX');
  assert.equal(enmascararDni(' 12345678 '), '12XXXXXX');
});

test('DNI: faltantes e inválidos nunca se muestran completos', () => {
  for (const valor of [null, undefined, '']) assert.equal(enmascararDni(valor), '--');
  for (const valor of ['123', '123456789', '1234abcd', 'ABCDEFGH']) {
    assert.equal(enmascararDni(valor), 'XXXXXXXX');
  }
});

test('DNI: el valor original sigue disponible para la búsqueda y las operaciones', () => {
  const paciente = Object.freeze({ dni: '09342204' });
  assert.equal(enmascararDni(paciente.dni), '09XXXXXX');
  assert.equal(paciente.dni, '09342204');
  assert.equal(paciente.dni.includes('09342204'), true);
});

test('La pestaña usa el PNG real de Nuvia y no el ícono de plantilla', () => {
  const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
  assert.match(html, /rel="icon" type="image\/png" href="\/src\/assets\/logo_tesis\.png"/);
  assert.equal(html.includes('/favicon.svg'), false);
  const png = readFileSync(new URL('../src/assets/logo_tesis.png', import.meta.url));
  assert.deepEqual([...png.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
});
