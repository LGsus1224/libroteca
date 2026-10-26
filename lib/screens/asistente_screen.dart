import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../controllers/libros_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_views.dart';
import 'detalle_libro_screen.dart';

class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _texto = TextEditingController();
  final _asistente = Get.find<AsistenteController>();
  final _libros = Get.find<LibrosController>();

  static const _sugerencias = ['Recomiéndame ciencia ficción', 'Un libro corto', '¿Cuáles son los mejor valorados?'];

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _enviar([String? t]) {
    final consulta = t ?? _texto.text;
    _texto.clear();
    _asistente.preguntar(consulta);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(children: [
      Expanded(
        child: Obx(() {
          if (_asistente.mensajes.isEmpty) {
            return VacioView(
              icono: Icons.smart_toy_outlined,
              titulo: 'Pregúntale a tu asistente de lectura',
              detalle: 'Te recomienda libros del catálogo según lo que ya reseñaste.',
              accion: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                for (final s in _sugerencias) ActionChip(label: Text(s), onPressed: () => _enviar(s)),
              ]),
            );
          }
          return ListView(padding: const EdgeInsets.all(AppTheme.espacio), children: [
            for (final m in _asistente.mensajes)
              Align(
                alignment: m.delUsuario ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
                  decoration: BoxDecoration(
                    color: m.esError
                        ? tema.colorScheme.errorContainer
                        : m.delUsuario
                            ? tema.colorScheme.primaryContainer
                            : tema.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.texto),
                    for (final id in m.libros)
                      if (_libros.porId(id) != null)
                        TextButton.icon(
                          onPressed: () => Get.to(() => DetalleLibroScreen(libroId: id)),
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: Text(_libros.porId(id)!.titulo),
                        ),
                  ]),
                ),
              ),
            if (_asistente.pensando.value) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          ]);
        }),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.espacio),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _texto,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(hintText: 'Escribe tu pregunta'),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => IconButton.filled(
                  tooltip: 'Enviar',
                  onPressed: _asistente.pensando.value ? null : _enviar,
                  icon: const Icon(Icons.send),
                )),
          ]),
        ),
      ),
    ]);
  }
}
