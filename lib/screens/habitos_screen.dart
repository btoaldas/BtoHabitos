import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/habitos_controller.dart';
import '../models/models.dart';
import '../services/session_authority.dart';
import '../widgets/estado_operacion.dart';
import 'habito_form_screen.dart';

class HabitosScreen extends StatelessWidget {
  const HabitosScreen({
    super.key,
    required this.controller,
    required this.identity,
  });
  final HabitosController controller;
  final SessionIdentity identity;

  Future<void> _delete(BuildContext context, Habito habito) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('¿Eliminar este hábito?'),
        content: Text(habito.datos.titulo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.remove(habito, identity);
  }

  @override
  Widget build(BuildContext context) => ContenidoPagina(
    child: Obx(() {
      if (controller.loading.value) {
        return const EstadoOperacion(
          loading: true,
          title: 'Buscando sus hábitos…',
        );
      }
      if (controller.error.value != null) {
        return EstadoOperacion(
          title: 'No pudimos cargar su rutina',
          message: controller.error.value,
          onRetry: controller.load,
          icon: Icons.cloud_off_outlined,
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Su rutina, paso a paso',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.completed} de ${controller.items.length} completados',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('habit-create'),
                onPressed: controller.mutating.value
                    ? null
                    : () => openHabitoForm(context, controller, identity),
                icon: const Icon(Icons.add),
                label: const Text('Crear hábito'),
              ),
            ),
            MensajeOperacion(controller.mutationError.value, error: true),
            MensajeOperacion(controller.feedback.value),
            if (controller.mutating.value)
              const LinearProgressIndicator(semanticsLabel: 'Guardando hábito'),
            if (controller.items.isEmpty)
              const EstadoOperacion(
                title: 'Un pequeño paso cuenta',
                message: 'Cree su primer hábito o elija una idea del Catálogo.',
              ),
            ...controller.items.map(
              (h) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            key: Key('complete-${h.id}'),
                            tooltip: h.datos.completado
                                ? 'Reabrir hábito'
                                : 'Completar hábito',
                            onPressed: controller.mutating.value
                                ? null
                                : () => controller.toggle(h, identity),
                            icon: Icon(
                              h.datos.completado
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.datos.titulo,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${categorias[h.datos.categoria]} · ${frecuencias[h.datos.frecuencia]} · ${tipos[h.datos.tipo]}',
                                  ),
                                  if (h.datos.descripcion.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(h.datos.descripcion),
                                    ),
                                  if (h.datos.completado)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text('Completado'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            key: Key('edit-${h.id}'),
                            onPressed: controller.mutating.value
                                ? null
                                : () => openHabitoForm(
                                    context,
                                    controller,
                                    identity,
                                    initial: h.datos,
                                    id: h.id,
                                  ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          TextButton.icon(
                            key: Key('delete-${h.id}'),
                            onPressed: controller.mutating.value
                                ? null
                                : () => _delete(context, h),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
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
