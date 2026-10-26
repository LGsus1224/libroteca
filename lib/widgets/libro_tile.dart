import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/libros_controller.dart';
import '../models/libro.dart';
import '../theme/app_theme.dart';

class LibroTile extends StatelessWidget {
  const LibroTile({super.key, required this.libro, required this.alTocar});
  final Libro libro;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final libros = Get.find<LibrosController>();
    final esquema = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: alTocar,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.espacio, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: esquema.primaryContainer,
          child: Text(libro.titulo.characters.first, style: TextStyle(color: esquema.onPrimaryContainer)),
        ),
        title: Text(libro.titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${libro.autor} · ${libro.genero}\n${libro.promedio == null ? 'Sin reseñas aún' : '★ ${libro.promedio} (${libro.totalResenas})'}'),
        isThreeLine: true,
        trailing: Obx(() {
          final favorito = libros.favoritosIds.contains(libro.id);
          return IconButton(
            tooltip: favorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
            icon: Icon(favorito ? Icons.favorite : Icons.favorite_border, color: favorito ? esquema.error : null),
            onPressed: () => libros.alternarFavorito(libro.id),
          );
        }),
      ),
    );
  }
}
