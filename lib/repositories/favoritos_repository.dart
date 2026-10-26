import 'package:hive_flutter/hive_flutter.dart';

/// Favoritos guardados en el teléfono con Hive: sobreviven al cierre de la app.
/// Cada persona tiene su propia lista (la clave es el id de usuario).
class FavoritosRepository {
  static const _caja = 'favoritos';

  static Future<void> iniciar() async {
    await Hive.initFlutter();
    await Hive.openBox<List<dynamic>>(_caja);
  }

  Box<List<dynamic>> get _box => Hive.box<List<dynamic>>(_caja);

  Set<int> leer(int usuarioId) => (_box.get('$usuarioId') ?? const []).whereType<int>().toSet();

  Future<void> guardar(int usuarioId, Set<int> ids) => _box.put('$usuarioId', ids.toList());
}
