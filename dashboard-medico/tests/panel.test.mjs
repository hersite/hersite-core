import test from 'node:test';
import assert from 'node:assert/strict';
import { ordenarTriaje } from '../src/utils/triaje.js';
import { completarMeses } from '../src/utils/tendencias.js';
import { probabilidadesModelo } from '../src/utils/probabilidades.js';

const caso = (id, nivel, fecha, activo = true) => ({
  gestante: { id, activo },
  ultima_evaluacion: nivel ? { id, nivel_riesgo: nivel, fecha_hora: fecha } : null,
});

test('Triaje: alto primero; el resto por fecha, sin depender del ID de perfil', () => {
  const filas = [
    caso(1, 'Riesgo_Bajo', '2026-11-07T09:00:00-05:00'),
    caso(2, 'Riesgo_Medio', '2026-11-06T09:00:00-05:00'),
    caso(3, 'Riesgo_Alto', '2026-10-01T09:00:00-05:00'),
    caso(4, 'Riesgo_Alto', '2026-11-01T09:00:00-05:00'),
    caso(5, null),
    caso(6, 'Riesgo_Alto', '2026-11-07T10:00:00-05:00', false),
  ];
  assert.deepEqual(ordenarTriaje(filas).map((f) => f.gestante.id), [4, 3, 1, 2, 5]);
  assert.deepEqual(filas.map((f) => f.gestante.id), [1, 2, 3, 4, 5, 6]);
});

test('Una evaluación nueva de una cuenta antigua cambia su posición en cada actualización', () => {
  const vieja = caso(1, 'Riesgo_Medio', '2026-10-01');
  const otra = caso(10, 'Riesgo_Bajo', '2026-11-01');
  assert.equal(ordenarTriaje([vieja, otra])[0].gestante.id, 10);
  const nueva = { ...vieja, ultima_evaluacion: { ...vieja.ultima_evaluacion, id: 20, fecha_hora: '2026-11-07' } };
  assert.equal(ordenarTriaje([nueva, otra])[0].gestante.id, 1);
});

test('Triaje: fechas inválidas, recepción alternativa y desempates deterministas', () => {
  const filas = [caso(1, null), caso(2, null), caso(3, 'Riesgo_Bajo', 'incorrecta')];
  filas[2].ultima_evaluacion.recibido_en = '2026-11-07T15:00:00Z';
  assert.deepEqual(ordenarTriaje(filas).map((f) => f.gestante.id), [3, 2, 1]);
  assert.deepEqual(ordenarTriaje([]), []);
});

test('Tendencias: enero a diciembre incluso sin ninguna evaluación', () => {
  const meses = completarMeses([], 2026);
  assert.equal(meses.length, 12);
  assert.equal(meses[0].key, '2026-01');
  assert.equal(meses[11].key, '2026-12');
  assert.ok(meses.every((m) => m.total === 0 && m.bajo === 0 && m.medio === 0 && m.alto === 0));
});

test('Tendencias: conserva valores y completa meses y años intermedios', () => {
  const actividad = { key: '2024-10', mes: 'Oct 2024', bajo: 2, medio: 3, alto: 1, total: 6 };
  const sinFecha = { key: 'sin-fecha', mes: 'Sin fecha', total: 1 };
  const meses = completarMeses([actividad, sinFecha], 2026);
  assert.equal(meses.length, 37);
  assert.deepEqual(meses.find((m) => m.key === '2024-10'), actividad);
  assert.equal(meses.find((m) => m.key === '2025-06').total, 0);
  assert.deepEqual(meses.at(-1), sinFecha);
});

test('Datos técnicos: valida el formato de probabilidades sin inventar valores', () => {
  assert.deepEqual(probabilidadesModelo([[0.1, 0.2, 0.7]]), [0.1, 0.2, 0.7]);
  assert.deepEqual(probabilidadesModelo([1, 0, 0]), [1, 0, 0]);
  assert.equal(probabilidadesModelo(null), null);
  assert.equal(probabilidadesModelo([1, 1, 1]), null);
});
