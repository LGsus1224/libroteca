import 'package:get/get.dart';

import '../services/api_client.dart';
import '../services/libros_service.dart';

class MensajeChat {
  final String texto;
  final bool delUsuario;
  final List<int> libros;
  final bool esError;
  const MensajeChat(this.texto, {this.delUsuario = false, this.libros = const [], this.esError = false});
}

class AsistenteController extends GetxController {
  AsistenteController(this._servicio);
  final LibrosService _servicio;

  final mensajes = <MensajeChat>[].obs;
  final pensando = false.obs;

  Future<void> preguntar(String consulta) async {
    final texto = consulta.trim();
    if (texto.isEmpty || pensando.value) return;
    mensajes.add(MensajeChat(texto, delUsuario: true));
    pensando.value = true;
    try {
      final r = await _servicio.preguntar(texto);
      mensajes.add(MensajeChat(r.respuesta, libros: r.libros));
    } on ApiException catch (e) {
      mensajes.add(MensajeChat(e.mensaje, esError: true));
    } finally {
      pensando.value = false;
    }
  }
}
