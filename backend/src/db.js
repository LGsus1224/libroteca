// Persistencia en un archivo JSON (data/db.json). Suficiente para el curso; en producción iría una base de datos.
const fs = require('fs');
const path = require('path');
const { DIR_DATOS } = require('./auth');

const ARCHIVO = path.join(DIR_DATOS, 'db.json');
const SEMILLA = path.join(__dirname, '..', 'seed', 'libros.json');

let datos;

function cargar() {
  fs.mkdirSync(DIR_DATOS, { recursive: true });
  if (fs.existsSync(ARCHIVO)) {
    datos = JSON.parse(fs.readFileSync(ARCHIVO, 'utf8'));
  } else {
    datos = { libros: JSON.parse(fs.readFileSync(SEMILLA, 'utf8')), usuarios: [], resenas: [], siguienteId: 1 };
    guardar();
  }
  return datos;
}

function guardar() {
  fs.writeFileSync(ARCHIVO + '.tmp', JSON.stringify(datos, null, 2));
  fs.renameSync(ARCHIVO + '.tmp', ARCHIVO);
}

const siguienteId = () => {
  const id = datos.siguienteId++;
  guardar();
  return id;
};

module.exports = { cargar, guardar, siguienteId, get: () => datos };
