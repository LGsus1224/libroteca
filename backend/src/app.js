const http = require('http');
const auth = require('./auth');
const db = require('./db');
const { responder } = require('./asistente');

class HttpError extends Error {
  constructor(status, detail) { super(typeof detail === 'string' ? detail : 'error'); this.status = status; this.detail = detail; }
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function leerJson(req) {
  return new Promise((resolve, reject) => {
    let cuerpo = '';
    req.on('data', (c) => { cuerpo += c; if (cuerpo.length > 20000) { reject(new HttpError(413, 'El cuerpo es demasiado grande.')); req.destroy(); } });
    req.on('end', () => {
      if (!cuerpo) return resolve({});
      try { resolve(JSON.parse(cuerpo)); } catch { reject(new HttpError(400, 'El cuerpo no es un JSON válido.')); }
    });
  });
}

function usuarioActual(req) {
  const cab = req.headers.authorization || '';
  const payload = cab.startsWith('Bearer ') ? auth.verificar(cab.slice(7)) : null;
  if (!payload) throw new HttpError(401, 'Necesitas iniciar sesión.');
  const usuario = db.get().usuarios.find((u) => u.id === payload.sub);
  if (!usuario) throw new HttpError(401, 'Necesitas iniciar sesión.');
  return usuario;
}

const publico = (u) => ({ id: u.id, nombre: u.nombre, email: u.email });
const campoError = (campo, msg) => ({ loc: ['body', campo], msg });

function validarCredenciales(b, conNombre) {
  const errores = [];
  if (conNombre && (typeof b.nombre !== 'string' || b.nombre.trim().length < 2)) errores.push(campoError('nombre', 'debe tener al menos 2 caracteres'));
  if (typeof b.email !== 'string' || !EMAIL.test(b.email.trim())) errores.push(campoError('email', 'no es un correo válido'));
  if (typeof b.password !== 'string' || b.password.length < 6) errores.push(campoError('password', 'debe tener al menos 6 caracteres'));
  if (errores.length) throw new HttpError(422, errores);
}

function resumenLibro(l, resenas) {
  const rs = resenas.filter((r) => r.libroId === l.id);
  return { ...l, promedio: rs.length ? Math.round((rs.reduce((a, r) => a + r.calificacion, 0) / rs.length) * 10) / 10 : null, totalResenas: rs.length };
}

const RUTAS = [
  ['GET', /^\/salud$/, async () => ({ estado: 'ok' })],

  ['POST', /^\/auth\/registro$/, async (req) => {
    const b = await leerJson(req);
    validarCredenciales(b, true);
    const email = b.email.trim().toLowerCase();
    const d = db.get();
    if (d.usuarios.some((u) => u.email === email)) throw new HttpError(400, 'Ya existe una cuenta con ese correo.');
    const usuario = { id: db.siguienteId(), nombre: b.nombre.trim(), email, passwordHash: auth.hashPassword(b.password) };
    d.usuarios.push(usuario);
    db.guardar();
    return { status: 201, body: { token: auth.firmar({ sub: usuario.id }), usuario: publico(usuario) } };
  }],

  ['POST', /^\/auth\/login$/, async (req) => {
    const b = await leerJson(req);
    validarCredenciales(b, false);
    const usuario = db.get().usuarios.find((u) => u.email === b.email.trim().toLowerCase());
    if (!usuario || !auth.verificarPassword(b.password, usuario.passwordHash)) throw new HttpError(401, 'Correo o contraseña incorrectos.');
    return { token: auth.firmar({ sub: usuario.id }), usuario: publico(usuario) };
  }],

  ['GET', /^\/auth\/yo$/, async (req) => publico(usuarioActual(req))],

  ['GET', /^\/libros$/, async (req, url) => {
    const d = db.get();
    const genero = url.searchParams.get('genero');
    const q = (url.searchParams.get('q') || '').toLowerCase();
    return d.libros
      .filter((l) => !genero || l.genero === genero)
      .filter((l) => !q || `${l.titulo} ${l.autor}`.toLowerCase().includes(q))
      .map((l) => resumenLibro(l, d.resenas));
  }],

  ['GET', /^\/libros\/(\d+)$/, async (req, url, [id]) => {
    const d = db.get();
    const l = d.libros.find((x) => x.id === Number(id));
    if (!l) throw new HttpError(404, 'El libro no existe.');
    return resumenLibro(l, d.resenas);
  }],

  ['GET', /^\/libros\/(\d+)\/resenas$/, async (req, url, [id]) => {
    const d = db.get();
    return d.resenas.filter((r) => r.libroId === Number(id)).sort((a, b) => b.creada.localeCompare(a.creada))
      .map((r) => ({ id: r.id, libroId: r.libroId, calificacion: r.calificacion, comentario: r.comentario, creada: r.creada,
        autorId: r.usuarioId, autorNombre: (d.usuarios.find((u) => u.id === r.usuarioId) || {}).nombre || 'Anónimo' }));
  }],

  ['POST', /^\/libros\/(\d+)\/resenas$/, async (req, url, [id]) => {
    const usuario = usuarioActual(req);
    const d = db.get();
    if (!d.libros.some((l) => l.id === Number(id))) throw new HttpError(404, 'El libro no existe.');
    const b = await leerJson(req);
    const errores = [];
    if (!Number.isInteger(b.calificacion) || b.calificacion < 1 || b.calificacion > 5) errores.push(campoError('calificacion', 'debe ser un entero entre 1 y 5'));
    if (typeof b.comentario !== 'string' || b.comentario.trim().length < 3 || b.comentario.length > 500) errores.push(campoError('comentario', 'debe tener entre 3 y 500 caracteres'));
    if (errores.length) throw new HttpError(422, errores);
    if (d.resenas.some((r) => r.libroId === Number(id) && r.usuarioId === usuario.id)) throw new HttpError(400, 'Ya reseñaste este libro. Elimina tu reseña para escribir otra.');
    const r = { id: db.siguienteId(), libroId: Number(id), usuarioId: usuario.id, calificacion: b.calificacion, comentario: b.comentario.trim(), creada: new Date().toISOString() };
    d.resenas.push(r);
    db.guardar();
    return { status: 201, body: { id: r.id, libroId: r.libroId, calificacion: r.calificacion, comentario: r.comentario, creada: r.creada, autorId: usuario.id, autorNombre: usuario.nombre } };
  }],

  ['DELETE', /^\/resenas\/(\d+)$/, async (req, url, [id]) => {
    const usuario = usuarioActual(req);
    const d = db.get();
    const i = d.resenas.findIndex((r) => r.id === Number(id));
    if (i < 0) throw new HttpError(404, 'La reseña no existe.');
    if (d.resenas[i].usuarioId !== usuario.id) throw new HttpError(403, 'Solo puedes eliminar tus propias reseñas.');
    d.resenas.splice(i, 1);
    db.guardar();
    return { status: 204 };
  }],

  ['POST', /^\/asistente$/, async (req) => {
    const usuario = usuarioActual(req);
    const b = await leerJson(req);
    if (typeof b.consulta !== 'string' || !b.consulta.trim() || b.consulta.length > 500) {
      throw new HttpError(422, [campoError('consulta', 'es obligatoria y no pasa de 500 caracteres')]);
    }
    return responder(b.consulta.trim(), db.get(), usuario.id);
  }],
];

function crearServidor() {
  db.cargar();
  return http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://localhost');
    const responder = (status, body) => {
      const cuerpo = body === undefined ? '' : JSON.stringify(body);
      res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type', 'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS' });
      res.end(cuerpo);
    };
    if (req.method === 'OPTIONS') return responder(204);
    try {
      let encontrada = false;
      for (const [metodo, patron, manejador] of RUTAS) {
        const m = url.pathname.match(patron);
        if (m && metodo === req.method) {
          encontrada = true;
          const r = await manejador(req, url, m.slice(1));
          // Registro: método, ruta y estado. Nunca cabeceras ni cuerpos (token y contraseñas).
          console.log(`${req.method} ${url.pathname} -> ${r && r.status ? r.status : 200}`);
          return r && r.status ? responder(r.status, r.body) : responder(200, r);
        }
        if (m) encontrada = true;
      }
      throw new HttpError(encontrada ? 405 : 404, encontrada ? 'Método no permitido.' : 'Ruta no encontrada.');
    } catch (e) {
      const status = e.status || 500;
      console.log(`${req.method} ${url.pathname} -> ${status}`);
      if (!e.status) console.error('Error interno:', e.message);
      responder(status, { detail: e.status ? e.detail : 'Error interno del servidor.' });
    }
  });
}

module.exports = { crearServidor };
