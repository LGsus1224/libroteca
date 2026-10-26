/// Dirección del backend de Libroteca. Se cambia al ejecutar con
/// `--dart-define=API_BASE_URL=http://<ip>:3000`. El valor por defecto es cómo
/// el emulador Android ve el `localhost` de tu computador. La app no conoce
/// ninguna clave de IA: el asistente vive en este mismo servidor.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
