import 'package:get/get.dart';

import '../models/resena.dart';
import '../services/api_client.dart';
import '../services/libros_service.dart';
import 'libros_controller.dart';

/// Reseñas del libro que se está viendo (colaborativas: las ven todas las personas).
class ResenasController extends GetxController {
  ResenasController(this._servicio, this._libros);

  final LibrosService _servicio;
  final LibrosController _libros;

  int libroId = 0;
  final resenas = <Resena>[].obs;
  final cargando = false.obs;
  final error = RxnString();
  final enviando = false.obs;
  final errorEnvio = RxnString();
  final calificacion = 0.obs;

  Future<void> abrir(int id) async {
    libroId = id;
    resenas.clear();
    calificacion.value = 0;
    errorEnvio.value = null;
    await cargar();
  }

  Future<void> cargar() async {
    cargando.value = true;
    error.value = null;
    try {
      resenas.assignAll(await _servicio.listarResenas(libroId));
    } on ApiException catch (e) {
      error.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Future<bool> publicar(String comentario) async {
    if (calificacion.value == 0) {
      errorEnvio.value = 'Elige una calificación de 1 a 5 estrellas.';
      return false;
    }
    enviando.value = true;
    errorEnvio.value = null;
    try {
      final r = await _servicio.crearResena(libroId, calificacion.value, comentario.trim());
      resenas.insert(0, r);
      calificacion.value = 0;
      await _libros.cargar(); // el promedio del catálogo cambió
      return true;
    } on ApiException catch (e) {
      errorEnvio.value = e.mensaje;
      return false;
    } finally {
      enviando.value = false;
    }
  }

  /// Devuelve un mensaje de error o null si se eliminó.
  Future<String?> eliminar(Resena r) async {
    try {
      await _servicio.eliminarResena(r.id);
      resenas.removeWhere((x) => x.id == r.id);
      await _libros.cargar();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }
}
