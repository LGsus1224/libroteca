class Libro {
  final int id;
  final String titulo;
  final String autor;
  final int anio;
  final String genero;
  final int paginas;
  final String sinopsis;
  final double? promedio;
  final int totalResenas;

  const Libro({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.anio,
    required this.genero,
    required this.paginas,
    required this.sinopsis,
    this.promedio,
    this.totalResenas = 0,
  });

  factory Libro.fromJson(Map<String, dynamic> json) => Libro(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        autor: json['autor'] as String,
        anio: json['anio'] as int,
        genero: json['genero'] as String,
        paginas: json['paginas'] as int,
        sinopsis: json['sinopsis'] as String,
        promedio: (json['promedio'] as num?)?.toDouble(),
        totalResenas: (json['totalResenas'] as int?) ?? 0,
      );
}
