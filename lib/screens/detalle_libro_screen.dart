import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/libros_controller.dart';
import '../controllers/resenas_controller.dart';
import '../models/resena.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_views.dart';

class DetalleLibroScreen extends StatefulWidget {
  const DetalleLibroScreen({super.key, required this.libroId});
  final int libroId;

  @override
  State<DetalleLibroScreen> createState() => _DetalleLibroScreenState();
}

class _DetalleLibroScreenState extends State<DetalleLibroScreen> {
  final _comentario = TextEditingController();
  final _libros = Get.find<LibrosController>();
  final _resenas = Get.find<ResenasController>();
  final _auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resenas.abrir(widget.libroId));
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (await _resenas.publicar(_comentario.text)) _comentario.clear();
  }

  Future<void> _eliminar(Resena r) async {
    final error = await _resenas.eliminar(r);
    if (error != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Obx(() {
      final libro = _libros.porId(widget.libroId);
      if (libro == null) {
        return Scaffold(appBar: AppBar(), body: const VacioView(icono: Icons.menu_book, titulo: 'Este libro ya no está disponible'));
      }
      final favorito = _libros.favoritosIds.contains(libro.id);
      return Scaffold(
        appBar: AppBar(
          title: Text(libro.titulo, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: favorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
              icon: Icon(favorito ? Icons.favorite : Icons.favorite_border),
              onPressed: () => _libros.alternarFavorito(libro.id),
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(AppTheme.espacio), children: [
          Text(libro.titulo, style: tema.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('${libro.autor} · ${libro.anio}', style: tema.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            Chip(label: Text(libro.genero)),
            Chip(label: Text('${libro.paginas} páginas')),
            Chip(avatar: const Icon(Icons.star, size: 18), label: Text(libro.promedio == null ? 'Sin reseñas' : '${libro.promedio} (${libro.totalResenas})')),
          ]),
          const SizedBox(height: 8),
          Text(libro.sinopsis),
          const Divider(height: AppTheme.espacio * 2),
          Text('Escribe tu reseña', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() => Row(children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i de 5',
                    onPressed: () => _resenas.calificacion.value = i,
                    icon: Icon(i <= _resenas.calificacion.value ? Icons.star : Icons.star_border, color: Colors.amber.shade700),
                  ),
              ])),
          TextField(
            controller: _comentario,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Tu comentario'),
          ),
          Obx(() => _resenas.errorEnvio.value == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_resenas.errorEnvio.value!, style: TextStyle(color: tema.colorScheme.error)),
                )),
          Obx(() => FilledButton(
                onPressed: _resenas.enviando.value ? null : _publicar,
                child: _resenas.enviando.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publicar reseña'),
              )),
          const Divider(height: AppTheme.espacio * 2),
          Text('Reseñas de la comunidad', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() {
            if (_resenas.cargando.value) return const Padding(padding: EdgeInsets.all(24), child: CargandoView(mensaje: 'Cargando reseñas…'));
            if (_resenas.error.value != null) {
              return SizedBox(height: 220, child: ErrorView(mensaje: _resenas.error.value!, alReintentar: _resenas.cargar));
            }
            if (_resenas.resenas.isEmpty) {
              return const SizedBox(
                height: 200,
                child: VacioView(icono: Icons.rate_review_outlined, titulo: 'Todavía no hay reseñas', detalle: 'Sé la primera persona en opinar sobre este libro.'),
              );
            }
            return Column(children: [
              for (final r in _resenas.resenas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text('${r.autorNombre} · ${'★' * r.calificacion}${'☆' * (5 - r.calificacion)}'),
                      subtitle: Text(r.comentario),
                      trailing: r.autorId == _auth.usuario.value?.id
                          ? IconButton(tooltip: 'Eliminar mi reseña', icon: const Icon(Icons.delete_outline), onPressed: () => _eliminar(r))
                          : null,
                    ),
                  ),
                ),
            ]);
          }),
        ]),
      );
    });
  }
}
