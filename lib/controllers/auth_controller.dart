import 'package:get/get.dart';

import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/secure_token_storage.dart';

enum EstadoSesion { iniciando, sinSesion, conSesion }

/// Estado de la sesión compartido por toda la app.
class AuthController extends GetxController {
  AuthController(this._api, this._servicio, this._almacen) {
    _api.alSesionCaducada = _caducada;
  }

  final ApiClient _api;
  final AuthService _servicio;
  final SecureTokenStorage _almacen;

  final estado = EstadoSesion.iniciando.obs;
  final usuario = Rxn<Usuario>();
  final enviando = false.obs;
  final error = RxnString();

  /// Al abrir la app: recupera el token guardado y comprueba que siga siendo válido.
  Future<void> iniciar() async {
    try {
      final token = await _almacen.leer();
      if (token == null) return _cerrar();
      _api.token = token;
      usuario.value = await _servicio.yo();
      estado.value = EstadoSesion.conSesion;
    } on ApiException catch (e) {
      // Sin red no se borra el token: solo se pide entrar de nuevo si el servidor lo rechazó.
      if (e.statusCode == 401) await _almacen.borrar();
      _cerrar(mensaje: e.statusCode == 401 ? null : e.mensaje);
    } catch (_) {
      _cerrar();
    }
  }

  Future<bool> iniciarSesion(String email, String password) =>
      _entrar(() => _servicio.iniciarSesion(email.trim(), password));

  Future<bool> registrar(String nombre, String email, String password) =>
      _entrar(() => _servicio.registrar(nombre.trim(), email.trim(), password));

  Future<bool> _entrar(Future<SesionIniciada> Function() accion) async {
    enviando.value = true;
    error.value = null;
    try {
      final s = await accion();
      _api.token = s.token;
      await _almacen.guardar(s.token);
      usuario.value = s.usuario;
      estado.value = EstadoSesion.conSesion;
      return true;
    } on ApiException catch (e) {
      error.value = e.mensaje;
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<void> cerrarSesion() async {
    await _almacen.borrar();
    _cerrar();
  }

  void _caducada() {
    if (estado.value != EstadoSesion.conSesion) return;
    _almacen.borrar();
    _cerrar(mensaje: 'Tu sesión caducó, inicia sesión de nuevo.');
  }

  void _cerrar({String? mensaje}) {
    _api.token = null;
    usuario.value = null;
    error.value = mensaje;
    estado.value = EstadoSesion.sinSesion;
  }
}
