// Carga .env (si existe) sin dependencias. Las variables ya definidas en el entorno ganan.
const fs = require('fs');
const path = require('path');

function cargarEnv() {
  const archivo = path.join(__dirname, '..', '.env');
  if (!fs.existsSync(archivo)) return;
  for (const linea of fs.readFileSync(archivo, 'utf8').split('\n')) {
    const m = linea.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && m[2] !== '' && process.env[m[1]] === undefined) process.env[m[1]] = m[2];
  }
}

module.exports = { cargarEnv };
