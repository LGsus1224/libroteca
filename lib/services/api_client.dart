import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

export 'api_exception.dart';

/// Cliente HTTP único de la app: una instancia de `dio` con la dirección del
/// backend, un tiempo máximo de 15 segundos y dos interceptores.
class ApiClient {
  ApiClient({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            )) {
    // Añade `Authorization: Bearer <token>` a toda petición cuando hay sesión.
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opciones, siguiente) {
        final t = token;
        if (t != null) opciones.headers['Authorization'] = 'Bearer $t';
        siguiente.next(opciones);
      },
    ));

    // Si el token caduca, cualquier pantalla recibe un 401: se avisa en un solo lugar.
    // El login se excluye: ahí un 401 solo significa «contraseña incorrecta».
    this.dio.interceptors.add(InterceptorsWrapper(
      onError: (error, siguiente) {
        final esLogin = error.requestOptions.path == '/auth/login';
        if (error.response?.statusCode == 401 && !esLogin) alSesionCaducada?.call();
        siguiente.next(error);
      },
    ));
  }

  final Dio dio;

  /// Token JWT de la sesión actual. Se guarda de forma persistente en `SecureTokenStorage`.
  String? token;

  /// Lo asigna `AuthController`: se llama cuando el servidor responde 401.
  void Function()? alSesionCaducada;

  Future<Response<dynamic>> get(String ruta, {Map<String, dynamic>? query}) =>
      _enviar(() => dio.get(ruta, queryParameters: query));

  Future<Response<dynamic>> post(String ruta, {Object? data}) => _enviar(() => dio.post(ruta, data: data));

  Future<Response<dynamic>> delete(String ruta) => _enviar(() => dio.delete(ruta));

  /// Único lugar con try/catch: todo error de `dio` sale como `ApiException`.
  Future<Response<dynamic>> _enviar(Future<Response<dynamic>> Function() peticion) async {
    try {
      return await peticion();
    } on DioException catch (e) {
      throw ApiException.desde(e);
    }
  }
}
