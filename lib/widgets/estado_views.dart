import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tres estados distintos y visibles de toda pantalla con datos.
class CargandoView extends StatelessWidget {
  const CargandoView({super.key, this.mensaje = 'Cargando…'});
  final String mensaje;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTheme.espacio),
          Text(mensaje),
        ]),
      );
}

class VacioView extends StatelessWidget {
  const VacioView({super.key, required this.icono, required this.titulo, this.detalle, this.accion});
  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.espacio * 2),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icono, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppTheme.espacio),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (detalle != null) ...[
              const SizedBox(height: 8),
              Text(detalle!, textAlign: TextAlign.center),
            ],
            if (accion != null) ...[const SizedBox(height: AppTheme.espacio), accion!],
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.mensaje, required this.alReintentar});
  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.espacio * 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off, size: 56, color: color),
          const SizedBox(height: AppTheme.espacio),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.espacio),
          OutlinedButton.icon(onPressed: alReintentar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ]),
      ),
    );
  }
}
