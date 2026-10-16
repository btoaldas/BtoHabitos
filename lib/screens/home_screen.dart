import 'package:flutter/material.dart';

import '../bindings/app_binding.dart';
import '../services/session_authority.dart';
import 'asistente_screen.dart';
import 'catalogo_screen.dart';
import 'habitos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.binding, required this.identity});
  final AppBinding binding;
  final SessionIdentity identity;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final b = widget.binding;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BtoHábitos'),
        actions: [
          IconButton(
            key: const Key('logout'),
            tooltip: 'Cerrar sesión',
            onPressed: b.auth.logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            CatalogoScreen(
              controller: b.catalogo,
              habitos: b.habitos,
              identity: widget.identity,
            ),
            HabitosScreen(controller: b.habitos, identity: widget.identity),
            AsistenteScreen(controller: b.asistente),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          if (_index == 2 && value != 2) b.asistente.discard();
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Mis hábitos',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Asistente',
          ),
        ],
      ),
    );
  }
}
