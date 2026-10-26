String? validarNombre(String? v) => (v == null || v.trim().length < 2) ? 'Escribe tu nombre (mínimo 2 letras).' : null;

String? validarEmail(String? v) =>
    (v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) ? 'Escribe un correo válido.' : null;

String? validarPassword(String? v) => (v == null || v.length < 6) ? 'La contraseña debe tener al menos 6 caracteres.' : null;
