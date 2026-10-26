import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    await _auth.iniciarSesion(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.espacio * 1.5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Icon(Icons.auto_stories, size: 72, color: tema.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('Libroteca', textAlign: TextAlign.center, style: tema.textTheme.headlineMedium),
                  Text('Reseñas de libros entre lectores', textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
                  const SizedBox(height: AppTheme.espacio * 2),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
                    validator: validarEmail,
                  ),
                  const SizedBox(height: AppTheme.espacio),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
                    validator: validarPassword,
                    onFieldSubmitted: (_) => _enviar(),
                  ),
                  const SizedBox(height: AppTheme.espacio),
                  Obx(() => _auth.error.value == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.espacio),
                          child: Text(_auth.error.value!, style: TextStyle(color: tema.colorScheme.error), textAlign: TextAlign.center),
                        )),
                  Obx(() => FilledButton(
                        onPressed: _auth.enviando.value ? null : _enviar,
                        child: _auth.enviando.value
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Iniciar sesión'),
                      )),
                  TextButton(
                    onPressed: () {
                      _auth.error.value = null;
                      Get.to(() => const RegistroScreen());
                    },
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
