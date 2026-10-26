// Contraseñas con scrypt y tokens JWT HS256, solo con el módulo `crypto` de Node.
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const DIR_DATOS = process.env.DATA_DIR || path.join(__dirname, '..', 'data');
const DURACION_TOKEN_S = 60 * 60 * 24; // 24 horas

function secreto() {
  if (process.env.JWT_SECRET) return process.env.JWT_SECRET;
  const archivo = path.join(DIR_DATOS, '.secret');
  fs.mkdirSync(DIR_DATOS, { recursive: true });
  if (!fs.existsSync(archivo)) fs.writeFileSync(archivo, crypto.randomBytes(32).toString('hex'), { mode: 0o600 });
  return fs.readFileSync(archivo, 'utf8');
}
const SECRETO = secreto();

const b64 = (x) => Buffer.from(x).toString('base64url');

function hashPassword(password) {
  const sal = crypto.randomBytes(16);
  const hash = crypto.scryptSync(password, sal, 64);
  return `${sal.toString('hex')}:${hash.toString('hex')}`;
}

function verificarPassword(password, guardado) {
  const [sal, hash] = guardado.split(':');
  const calculado = crypto.scryptSync(password, Buffer.from(sal, 'hex'), 64);
  return crypto.timingSafeEqual(calculado, Buffer.from(hash, 'hex'));
}

function firmar(payload) {
  const cuerpo = b64(JSON.stringify({ alg: 'HS256', typ: 'JWT' })) + '.' +
    b64(JSON.stringify({ ...payload, exp: Math.floor(Date.now() / 1000) + DURACION_TOKEN_S }));
  const firma = crypto.createHmac('sha256', SECRETO).update(cuerpo).digest('base64url');
  return `${cuerpo}.${firma}`;
}

/// Devuelve el payload si el token es válido y no ha caducado; si no, null.
function verificar(token) {
  const partes = (token || '').split('.');
  if (partes.length !== 3) return null;
  const esperada = crypto.createHmac('sha256', SECRETO).update(`${partes[0]}.${partes[1]}`).digest();
  const recibida = Buffer.from(partes[2], 'base64url');
  if (esperada.length !== recibida.length || !crypto.timingSafeEqual(esperada, recibida)) return null;
  try {
    const payload = JSON.parse(Buffer.from(partes[1], 'base64url').toString());
    return payload.exp > Date.now() / 1000 ? payload : null;
  } catch {
    return null;
  }
}

module.exports = { hashPassword, verificarPassword, firmar, verificar, DIR_DATOS };
