import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/asistente_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/libros_controller.dart';
import 'controllers/resenas_controller.dart';
import 'repositories/favoritos_repository.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/libros_service.dart';
import 'services/secure_token_storage.dart';
import 'theme/app_theme.dart';
import 'widgets/estado_views.dart';

/// Crea los servicios y controladores una sola vez y los deja disponibles con `Get.find`.
void registrarDependencias() {
  final api = Get.put(ApiClient(), permanent: true);
  final libros = Get.put(LibrosService(api), permanent: true);
  final auth = Get.put(AuthController(api, AuthService(api), SecureTokenStorage()), permanent: true);
  final catalogo = Get.put(LibrosController(libros, FavoritosRepository(), auth), permanent: true);
  Get.put(ResenasController(libros, catalogo), permanent: true);
  Get.put(AsistenteController(libros), permanent: true);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Un error inesperado no debe dejar la app en una pantalla roja o en blanco.
  FlutterError.onError = (d) => debugPrint('Error de Flutter: ${d.exceptionAsString()}');
  PlatformDispatcher.instance.onError = (error, pila) {
    debugPrint('Error no capturado: $error');
    return true;
  };
  ErrorWidget.builder = (_) => const VacioView(icono: Icons.error_outline, titulo: 'Algo salió mal', detalle: 'Vuelve atrás e inténtalo de nuevo.');

  await FavoritosRepository.iniciar();
  registrarDependencias();
  Get.find<AuthController>().iniciar();
  runApp(const LibrotecaApp());
}

class LibrotecaApp extends StatelessWidget {
  const LibrotecaApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: 'Libroteca',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro(),
        darkTheme: AppTheme.oscuro(),
        locale: const Locale('es'),
        home: const _Raiz(),
      );
}

/// Según el estado de la sesión muestra la carga inicial, el login o la app.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() => switch (auth.estado.value) {
          EstadoSesion.iniciando => const Scaffold(body: CargandoView(mensaje: 'Abriendo Libroteca…')),
          EstadoSesion.sinSesion => const LoginScreen(),
          EstadoSesion.conSesion => const HomeScreen(),
        });
  }
}
