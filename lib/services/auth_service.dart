import '../models/usuario.dart';
import 'api_client.dart';

class SesionIniciada {
  final String token;
  final Usuario usuario;
  const SesionIniciada(this.token, this.usuario);
}

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  SesionIniciada _sesion(Object? json) {
    final m = json as Map<String, dynamic>;
    return SesionIniciada(m['token'] as String, Usuario.fromJson(m['usuario'] as Map<String, dynamic>));
  }

  Future<SesionIniciada> registrar(String nombre, String email, String password) async =>
      _sesion((await _api.post('/auth/registro', data: {'nombre': nombre, 'email': email, 'password': password})).data);

  Future<SesionIniciada> iniciarSesion(String email, String password) async =>
      _sesion((await _api.post('/auth/login', data: {'email': email, 'password': password})).data);

  Future<Usuario> yo() async => Usuario.fromJson((await _api.get('/auth/yo')).data as Map<String, dynamic>);
}
