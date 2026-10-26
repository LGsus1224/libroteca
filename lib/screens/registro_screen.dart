import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    final ok = await _auth.registrar(_nombre.text, _email.text, _password.text);
    if (ok) Get.until((r) => r.isFirst); // la raíz muestra la app al haber sesión
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.espacio * 1.5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextFormField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                    validator: validarNombre,
                  ),
                  const SizedBox(height: AppTheme.espacio),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
                    validator: validarEmail,
                  ),
                  const SizedBox(height: AppTheme.espacio),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6)', prefixIcon: Icon(Icons.lock_outline)),
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
                            : const Text('Crear cuenta'),
                      )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
