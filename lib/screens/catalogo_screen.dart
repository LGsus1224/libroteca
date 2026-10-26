import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/libros_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/estado_views.dart';
import '../widgets/libro_tile.dart';
import 'detalle_libro_screen.dart';

class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LibrosController>();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.espacio, AppTheme.espacio, AppTheme.espacio, 8),
        child: TextField(
          onChanged: (v) => c.busqueda.value = v,
          decoration: const InputDecoration(hintText: 'Buscar por título o autor', prefixIcon: Icon(Icons.search)),
        ),
      ),
      Obx(() => SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.espacio),
              children: [
                for (final g in [null, ...c.generos])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g ?? 'Todos'),
                      selected: c.genero.value == g,
                      onSelected: (_) => c.genero.value = g,
                    ),
                  ),
              ],
            ),
          )),
      Expanded(
        child: Obx(() {
          if (c.cargando.value && c.libros.isEmpty) return const CargandoView(mensaje: 'Cargando libros…');
          if (c.error.value != null && c.libros.isEmpty) return ErrorView(mensaje: c.error.value!, alReintentar: c.cargar);
          final lista = c.visibles;
          if (lista.isEmpty) {
            return VacioView(
              icono: Icons.search_off,
              titulo: 'No hay libros con esos filtros',
              detalle: 'Prueba con otra búsqueda o con otro género.',
              accion: TextButton(
                onPressed: () {
                  c.busqueda.value = '';
                  c.genero.value = null;
                },
                child: const Text('Limpiar filtros'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: c.cargar,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.espacio),
              itemCount: lista.length,
              separatorBuilder: (contexto, indice) => const SizedBox(height: 8),
              itemBuilder: (_, i) => LibroTile(libro: lista[i], alTocar: () => Get.to(() => DetalleLibroScreen(libroId: lista[i].id))),
            ),
          );
        }),
      ),
    ]);
  }
}
