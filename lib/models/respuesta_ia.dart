/// Respuesta del asistente: un texto y los ids de los libros que recomienda.
class RespuestaIA {
  final String respuesta;
  final List<int> libros;
  const RespuestaIA({required this.respuesta, this.libros = const []});

  /// La respuesta de una IA es un dato que se valida, no código en el que confiar.
  factory RespuestaIA.fromJson(Map<String, dynamic> json) => RespuestaIA(
        respuesta: (json['respuesta'] as String?) ?? 'El asistente no devolvió ninguna respuesta.',
        libros: (json['libros'] is List) ? (json['libros'] as List).whereType<int>().toList() : const [],
      );
}
