import '../models/libro.dart';
import '../models/resena.dart';
import '../models/respuesta_ia.dart';
import 'api_client.dart';

/// Acceso remoto a libros, reseñas y asistente. Es la única capa que conoce las rutas HTTP.
class LibrosService {
  LibrosService(this._api);
  final ApiClient _api;

  Future<List<Libro>> listarLibros() async {
    final datos = (await _api.get('/libros')).data as List;
    return datos.map((e) => Libro.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Resena>> listarResenas(int libroId) async {
    final datos = (await _api.get('/libros/$libroId/resenas')).data as List;
    return datos.map((e) => Resena.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Resena> crearResena(int libroId, int calificacion, String comentario) async {
    final r = await _api.post('/libros/$libroId/resenas', data: {'calificacion': calificacion, 'comentario': comentario});
    return Resena.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> eliminarResena(int id) async {
    await _api.delete('/resenas/$id');
  }

  Future<RespuestaIA> preguntar(String consulta) async {
    final r = await _api.post('/asistente', data: {'consulta': consulta});
    return RespuestaIA.fromJson(r.data as Map<String, dynamic>);
  }
}
