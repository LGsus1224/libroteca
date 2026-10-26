// Asistente de lectura. La clave del proveedor de IA vive SOLO aquí (variable de entorno).
// Con GEMINI_API_KEY consulta al modelo; sin ella responde con reglas simples.

const norm = (s) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');

function promedio(resenas) {
  return resenas.length ? resenas.reduce((a, r) => a + r.calificacion, 0) / resenas.length : null;
}

/// Resumen que se envía al modelo: nunca incluye correos ni contraseñas.
function contexto(datos, usuarioId) {
  return datos.libros.map((l) => {
    const rs = datos.resenas.filter((r) => r.libroId === l.id);
    const mia = rs.find((r) => r.usuarioId === usuarioId);
    return { id: l.id, titulo: l.titulo, autor: l.autor, genero: l.genero, paginas: l.paginas,
      promedio: promedio(rs), miCalificacion: mia ? mia.calificacion : null };
  });
}

function porReglas(consulta, libros) {
  const q = norm(consulta);
  const sinLeer = libros.filter((l) => l.miCalificacion === null);
  const orden = (a, b) => (b.promedio ?? 0) - (a.promedio ?? 0);
  let elegidos = [];
  let intro;

  const genero = [...new Set(libros.map((l) => l.genero))].find((g) => q.includes(norm(g)));
  if (genero) {
    elegidos = sinLeer.filter((l) => l.genero === genero).sort(orden).slice(0, 3);
    intro = `Si te gusta ${genero.toLowerCase()}, te recomiendo`;
  } else if (/(corto|breve|rapido|poco tiempo)/.test(q)) {
    elegidos = [...sinLeer].sort((a, b) => a.paginas - b.paginas).slice(0, 3);
    intro = 'Para una lectura corta, prueba con';
  } else if (/(mejor|popular|valorad|top)/.test(q)) {
    elegidos = [...libros].filter((l) => l.promedio !== null).sort(orden).slice(0, 3);
    intro = 'Los mejor valorados por la comunidad son';
  } else if (/(recomiend|sugier|leer|siguiente)/.test(q)) {
    elegidos = [...sinLeer].sort(orden).slice(0, 3);
    intro = 'Aún no has calificado estos libros y te pueden gustar:';
  }
  if (!elegidos.length) {
    return { respuesta: 'No entendí tu pregunta. Prueba con: «recomiéndame algo de ciencia ficción», «un libro corto» o «cuáles son los mejor valorados».', libros: [] };
  }
  return { respuesta: `${intro} ${elegidos.map((l) => `«${l.titulo}» (${l.autor})`).join(', ')}.`, libros: elegidos.map((l) => l.id) };
}

async function porGemini(consulta, libros) {
  const modelo = process.env.GEMINI_MODEL || 'gemini-2.5-flash-lite';
  const instruccion = 'Eres un asistente de lectura. Responde en español, en máximo 4 frases, usando SOLO estos libros. ' +
    'Devuelve JSON: {"respuesta": texto, "libros": [ids recomendados]}.\nLibros: ' + JSON.stringify(libros);
  const ctrl = new AbortController();
  const temporizador = setTimeout(() => ctrl.abort(), 15000);
  try {
    const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`, {
      method: 'POST',
      signal: ctrl.signal,
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': process.env.GEMINI_API_KEY },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: `${instruccion}\nPregunta: ${consulta}` }] }],
        generationConfig: { responseMimeType: 'application/json' },
      }),
    });
    if (r.status === 429) throw Object.assign(new Error('Se agotó la cuota gratuita de la IA. Inténtalo más tarde.'), { status: 429 });
    if (!r.ok) throw Object.assign(new Error('El proveedor de IA rechazó la petición.'), { status: 502 });
    const texto = (await r.json()).candidates?.[0]?.content?.parts?.[0]?.text;
    const salida = JSON.parse(texto);
    const ids = new Set(libros.map((l) => l.id));
    return {
      respuesta: String(salida.respuesta || '').slice(0, 800) || 'La IA no devolvió respuesta.',
      libros: Array.isArray(salida.libros) ? salida.libros.filter((i) => ids.has(i)).slice(0, 5) : [],
    };
  } catch (e) {
    if (e.status) throw e;
    if (e.name === 'AbortError') throw Object.assign(new Error('La IA tardó demasiado en responder.'), { status: 504 });
    throw Object.assign(new Error('No se pudo obtener respuesta de la IA.'), { status: 502 });
  } finally {
    clearTimeout(temporizador);
  }
}

async function responder(consulta, datos, usuarioId) {
  const libros = contexto(datos, usuarioId);
  return process.env.GEMINI_API_KEY ? porGemini(consulta, libros) : porReglas(consulta, libros);
}

module.exports = { responder, porReglas };
