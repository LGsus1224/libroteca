require('./src/env').cargarEnv();
const { crearServidor } = require('./src/app');

const puerto = Number(process.env.PORT) || 3000;
crearServidor().listen(puerto, '0.0.0.0', () => {
  const modo = process.env.GEMINI_API_KEY ? 'GEMINI' : 'REGLAS';
  console.log(`Libroteca backend en http://localhost:${puerto} (asistente en modo ${modo})`);
});
