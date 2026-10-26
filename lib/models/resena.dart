class Resena {
  final int id;
  final int libroId;
  final int calificacion;
  final String comentario;
  final DateTime creada;
  final int autorId;
  final String autorNombre;

  const Resena({
    required this.id,
    required this.libroId,
    required this.calificacion,
    required this.comentario,
    required this.creada,
    required this.autorId,
    required this.autorNombre,
  });

  factory Resena.fromJson(Map<String, dynamic> json) => Resena(
        id: json['id'] as int,
        libroId: json['libroId'] as int,
        calificacion: json['calificacion'] as int,
        comentario: json['comentario'] as String,
        creada: DateTime.parse(json['creada'] as String),
        autorId: json['autorId'] as int,
        autorNombre: json['autorNombre'] as String,
      );
}
