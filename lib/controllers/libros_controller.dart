import 'package:get/get.dart';

import '../models/libro.dart';
import '../repositories/favoritos_repository.dart';
import '../services/api_client.dart';
import '../services/libros_service.dart';
import 'auth_controller.dart';

/// Catálogo de libros, filtros y favoritos. Lo comparten el catálogo, los
/// favoritos, el detalle y el asistente.
class LibrosController extends GetxController {
  LibrosController(this._servicio, this._favoritos, this._auth);

  final LibrosService _servicio;
  final FavoritosRepository _favoritos;
  final AuthController _auth;

  final libros = <Libro>[].obs;
  final cargando = false.obs;
  final error = RxnString();
  final genero = RxnString(); // null = todos
  final busqueda = ''.obs;
  final favoritosIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Cada vez que cambia la persona con sesión se recargan sus favoritos y el catálogo.
    ever(_auth.usuario, (u) {
      favoritosIds.assignAll(u == null ? <int>{} : _favoritos.leer(u.id));
      if (u != null) cargar();
    });
    final u = _auth.usuario.value;
    if (u != null) {
      favoritosIds.assignAll(_favoritos.leer(u.id));
      cargar();
    }
  }

  List<String> get generos => (libros.map((l) => l.genero).toSet().toList()..sort());

  List<Libro> get visibles {
    final q = busqueda.value.trim().toLowerCase();
    return libros
        .where((l) => genero.value == null || l.genero == genero.value)
        .where((l) => q.isEmpty || '${l.titulo} ${l.autor}'.toLowerCase().contains(q))
        .toList();
  }

  List<Libro> get favoritos => libros.where((l) => favoritosIds.contains(l.id)).toList();

  Libro? porId(int id) => libros.firstWhereOrNull((l) => l.id == id);

  Future<void> cargar() async {
    cargando.value = true;
    error.value = null;
    try {
      libros.assignAll(await _servicio.listarLibros());
    } on ApiException catch (e) {
      error.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Future<void> alternarFavorito(int libroId) async {
    final u = _auth.usuario.value;
    if (u == null) return;
    favoritosIds.contains(libroId) ? favoritosIds.remove(libroId) : favoritosIds.add(libroId);
    await _favoritos.guardar(u.id, favoritosIds.toSet());
  }
}
