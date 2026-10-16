import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/catalogo_controller.dart';
import '../controllers/habitos_controller.dart';
import '../models/models.dart';
import '../services/session_authority.dart';
import '../widgets/estado_operacion.dart';
import 'habito_form_screen.dart';

class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({
    super.key,
    required this.controller,
    required this.habitos,
    required this.identity,
  });
  final CatalogoController controller;
  final HabitosController habitos;
  final SessionIdentity identity;

  Future<void> _detail(BuildContext context, Plantilla p) async {
    final create = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  p.datos.titulo,
                  style: Theme.of(sheet).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  '${categorias[p.datos.categoria]} · ${frecuencias[p.datos.frecuencia]} · ${tipos[p.datos.tipo]}',
                ),
                const SizedBox(height: 16),
                Text(p.datos.descripcion),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(sheet).pop(true),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear desde plantilla'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheet).pop(false),
                  child: const Text('Volver al catálogo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (create == true && context.mounted) {
      await openHabitoForm(context, habitos, identity, initial: p.datos);
    }
  }

  @override
  Widget build(BuildContext context) => ContenidoPagina(
    child: Obx(() {
      if (controller.loading.value) {
        return const EstadoOperacion(
          loading: true,
          title: 'Preparando su catálogo…',
        );
      }
      if (controller.error.value != null) {
        return EstadoOperacion(
          title: 'El catálogo necesita un momento',
          message: controller.error.value,
          onRetry: controller.load,
          icon: Icons.cloud_off_outlined,
        );
      }
      final visible = controller.visible;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Una idea para empezar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.items.length} plantillas para inspirar su próxima rutina.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: FilterChip(
                  label: const Text('Solo favoritos'),
                  selected: controller.onlyFavorites.value,
                  avatar: const Icon(Icons.star_outline, size: 20),
                  onSelected: (value) => controller.onlyFavorites.value = value,
                ),
              ),
            ),
            if (controller.favoritesLoading.value)
              const LinearProgressIndicator(
                semanticsLabel: 'Guardando favoritos',
              ),
            MensajeOperacion(
              controller.favoritesError.value,
              error: true,
              onRetry: controller.loadFavorites,
            ),
            if (visible.isEmpty)
              EstadoOperacion(
                title: controller.onlyFavorites.value
                    ? 'Sus favoritos empiezan aquí'
                    : 'No hay plantillas disponibles',
                message: controller.onlyFavorites.value
                    ? 'Toque la estrella de una plantilla para guardarla.'
                    : 'Actualice el catálogo para volver a consultar.',
                onRetry: controller.onlyFavorites.value
                    ? null
                    : controller.load,
              ),
            ...visible.map(
              (p) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  title: Text(p.datos.titulo),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${categorias[p.datos.categoria]} · ${frecuencias[p.datos.frecuencia]}',
                    ),
                  ),
                  onTap: () => _detail(context, p),
                  trailing: IconButton(
                    key: Key('favorite-${p.id}'),
                    tooltip: controller.favoriteIds.contains(p.id)
                        ? 'Quitar de favoritos'
                        : 'Guardar favorito',
                    onPressed: controller.favoritesLoading.value
                        ? null
                        : () => controller.toggleFavorite(p.id),
                    icon: Icon(
                      controller.favoriteIds.contains(p.id)
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }),
  );
}
