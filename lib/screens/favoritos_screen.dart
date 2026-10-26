import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/libros_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_views.dart';
import '../widgets/libro_tile.dart';
import 'detalle_libro_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LibrosController>();
    return Obx(() {
      if (c.cargando.value && c.libros.isEmpty) return const CargandoView();
      if (c.error.value != null && c.libros.isEmpty) return ErrorView(mensaje: c.error.value!, alReintentar: c.cargar);
      final lista = c.favoritos;
      if (lista.isEmpty) {
        return const VacioView(
          icono: Icons.favorite_border,
          titulo: 'Aún no tienes favoritos',
          detalle: 'Toca el corazón de un libro del catálogo para guardarlo aquí. Se conservan aunque cierres la app.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppTheme.espacio),
        itemCount: lista.length,
        separatorBuilder: (contexto, indice) => const SizedBox(height: 8),
        itemBuilder: (_, i) => LibroTile(libro: lista[i], alTocar: () => Get.to(() => DetalleLibroScreen(libroId: lista[i].id))),
      );
    });
  }
}
