import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'asistente_screen.dart';
import 'catalogo_screen.dart';
import 'favoritos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pestana = 0.obs;
  final _auth = Get.find<AuthController>();

  static const _titulos = ['Libroteca', 'Mis favoritos', 'Asistente de lectura'];
  static const _pantallas = [CatalogoScreen(), FavoritosScreen(), AsistenteScreen()];

  Future<void> _confirmarSalida() async {
    final salir = await Get.dialog<bool>(AlertDialog(
      title: const Text('Cerrar sesión'),
      content: Text('¿Salir de la cuenta de ${_auth.usuario.value?.nombre ?? ''}?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Get.back(result: true), child: const Text('Salir')),
      ],
    ));
    if (salir == true) await _auth.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) => Obx(() => Scaffold(
        appBar: AppBar(
          title: Text(_titulos[_pestana.value]),
          actions: [
            IconButton(tooltip: 'Cerrar sesión (${_auth.usuario.value?.nombre ?? ''})', icon: const Icon(Icons.logout), onPressed: _confirmarSalida),
          ],
        ),
        body: IndexedStack(index: _pestana.value, children: _pantallas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _pestana.value,
          onDestinationSelected: (i) => _pestana.value = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Libros'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoritos'),
            NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'Asistente'),
          ],
        ),
      ));
}
