const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

process.env.DATA_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'libroteca-'));
delete process.env.GEMINI_API_KEY;
const { crearServidor } = require('../src/app');

let base;
let servidor;
test.before(async () => {
  servidor = crearServidor();
  await new Promise((r) => servidor.listen(0, r));
  base = `http://localhost:${servidor.address().port}`;
});
test.after(() => servidor.close());

const llamar = async (ruta, { metodo = 'GET', token, cuerpo } = {}) => {
  const r = await fetch(base + ruta, { method: metodo, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: cuerpo ? JSON.stringify(cuerpo) : undefined });
  const texto = await r.text();
  return { status: r.status, json: texto ? JSON.parse(texto) : null };
};

test('hay al menos 20 libros', async () => {
  const r = await llamar('/libros');
  assert.equal(r.status, 200);
  assert.ok(r.json.length >= 20);
});

test('registro, login y errores de autenticación', async () => {
  assert.equal((await llamar('/auth/registro', { metodo: 'POST', cuerpo: { nombre: 'A', email: 'x', password: '1' } })).status, 422);
  const ok = await llamar('/auth/registro', { metodo: 'POST', cuerpo: { nombre: 'Ana', email: 'ana@ejemplo.com', password: 'secreta1' } });
  assert.equal(ok.status, 201);
  assert.equal((await llamar('/auth/registro', { metodo: 'POST', cuerpo: { nombre: 'Ana', email: 'ana@ejemplo.com', password: 'secreta1' } })).status, 400);
  assert.equal((await llamar('/auth/login', { metodo: 'POST', cuerpo: { email: 'ana@ejemplo.com', password: 'otraclave' } })).status, 401);
  assert.equal((await llamar('/auth/login', { metodo: 'POST', cuerpo: { email: 'ana@ejemplo.com', password: 'secreta1' } })).status, 200);
});

test('reseñas: requieren sesión, validan y solo el autor elimina', async () => {
  const ana = (await llamar('/auth/registro', { metodo: 'POST', cuerpo: { nombre: 'Ana', email: 'ana2@ejemplo.com', password: 'secreta1' } })).json.token;
  const luis = (await llamar('/auth/registro', { metodo: 'POST', cuerpo: { nombre: 'Luis', email: 'luis@ejemplo.com', password: 'secreta1' } })).json.token;
  const nueva = { calificacion: 5, comentario: 'Excelente lectura' };
  assert.equal((await llamar('/libros/1/resenas', { metodo: 'POST', cuerpo: nueva })).status, 401);
  assert.equal((await llamar('/libros/1/resenas', { metodo: 'POST', token: ana, cuerpo: { calificacion: 9, comentario: '' } })).status, 422);
  const creada = await llamar('/libros/1/resenas', { metodo: 'POST', token: ana, cuerpo: nueva });
  assert.equal(creada.status, 201);
  assert.equal((await llamar('/libros/1/resenas', { metodo: 'POST', token: ana, cuerpo: nueva })).status, 400);
  // Otro usuario ve la reseña (colaborativo) pero no puede borrarla.
  assert.equal((await llamar('/libros/1/resenas')).json.length, 1);
  assert.equal((await llamar(`/resenas/${creada.json.id}`, { metodo: 'DELETE', token: luis })).status, 403);
  assert.equal((await llamar(`/resenas/${creada.json.id}`, { metodo: 'DELETE', token: ana })).status, 204);
  assert.equal((await llamar('/libros/1/resenas')).json.length, 0);
});

test('asistente: exige sesión y recomienda por reglas', async () => {
  assert.equal((await llamar('/asistente', { metodo: 'POST', cuerpo: { consulta: 'hola' } })).status, 401);
  const t = (await llamar('/auth/registro', { metodo: 'POST', cuerpo: { nombre: 'Eva', email: 'eva@ejemplo.com', password: 'secreta1' } })).json.token;
  assert.equal((await llamar('/asistente', { metodo: 'POST', token: t, cuerpo: {} })).status, 422);
  const r = await llamar('/asistente', { metodo: 'POST', token: t, cuerpo: { consulta: 'recomiéndame ciencia ficción' } });
  assert.equal(r.status, 200);
  assert.ok(r.json.libros.length > 0);
});
