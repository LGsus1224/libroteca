import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libroteca/models/respuesta_ia.dart';
import 'package:libroteca/services/api_exception.dart';
import 'package:libroteca/utils/validadores.dart';
import 'package:libroteca/widgets/estado_views.dart';
import 'package:dio/dio.dart';

DioException _respuesta(int codigo, Object? datos, {String ruta = '/libros'}) {
  final opciones = RequestOptions(path: ruta);
  return DioException(
    requestOptions: opciones,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: opciones, statusCode: codigo, data: datos),
  );
}

void main() {
  group('ApiException: un mensaje distinto por tipo de error', () {
    test('400 muestra el detalle del servidor', () {
      expect(ApiException.desde(_respuesta(400, {'detail': 'Ya existe una cuenta con ese correo.'})).mensaje,
          'Ya existe una cuenta con ese correo.');
    });

    test('401 en login es credenciales; en otra ruta es sesión caducada', () {
      expect(ApiException.desde(_respuesta(401, {'detail': 'Correo o contraseña incorrectos.'}, ruta: '/auth/login')).mensaje,
          'Correo o contraseña incorrectos.');
      expect(ApiException.desde(_respuesta(401, {'detail': 'x'})).mensaje, contains('sesión caducó'));
    });

    test('422 lista los campos con error', () {
      final e = ApiException.desde(_respuesta(422, {
        'detail': [
          {'loc': ['body', 'email'], 'msg': 'no es un correo válido'}
        ]
      }));
      expect(e.mensaje, 'Datos inválidos: email no es un correo válido');
    });

    test('5xx y sin conexión son mensajes diferentes', () {
      final servidor = ApiException.desde(_respuesta(503, null)).mensaje;
      final red = ApiException.desde(DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionError)).mensaje;
      expect(servidor, contains('problema'));
      expect(red, contains('No hay conexión'));
      expect(servidor, isNot(red));
    });
  });

  test('RespuestaIA descarta ids que no son enteros', () {
    final r = RespuestaIA.fromJson({'respuesta': 'Hola', 'libros': [1, 'x', 3]});
    expect(r.libros, [1, 3]);
  });

  test('validadores', () {
    expect(validarEmail('a@b.co'), isNull);
    expect(validarEmail('malo'), isNotNull);
    expect(validarPassword('12345'), isNotNull);
    expect(validarNombre('Ana'), isNull);
  });

  testWidgets('las vistas de carga, vacío y error son distintas', (tester) async {
    var reintentos = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: Column(children: [
          const SizedBox(height: 150, child: CargandoView(mensaje: 'Cargando libros…')),
          const SizedBox(height: 250, child: VacioView(icono: Icons.inbox, titulo: 'Nada por aquí')),
          SizedBox(height: 250, child: ErrorView(mensaje: 'No hay conexión', alReintentar: () => reintentos++)),
        ])),
      ),
    ));
    expect(find.text('Cargando libros…'), findsOneWidget);
    expect(find.text('Nada por aquí'), findsOneWidget);
    expect(find.text('No hay conexión'), findsOneWidget);
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    expect(reintentos, 1);
  });
}
