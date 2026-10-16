import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../models/models.dart';
import '../widgets/estado_operacion.dart';

class AsistenteScreen extends StatelessWidget {
  const AsistenteScreen({super.key, required this.controller});
  final AsistenteController controller;

  @override
  Widget build(BuildContext context) => ContenidoPagina(
    child: Obx(() {
      final response = controller.reply.value;
      final draft = response?.propuesta;
      final busy = controller.loading.value || controller.confirming.value;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Encuentre su siguiente paso',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Pida una idea sencilla para organizarse, aprender o cuidar su rutina.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Su avance',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (controller.habitos.loading.value)
                    const Text('Consultando su rutina…')
                  else if (controller.habitos.error.value != null) ...[
                    const Text('No se pudo consultar su avance.'),
                    TextButton(
                      onPressed: controller.habitos.load,
                      child: const Text('Actualizar avance'),
                    ),
                  ] else
                    Text(
                      '${controller.habitos.completed} completados · ${controller.habitos.items.length} en su rutina',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('assistant-input'),
            controller: controller.input,
            enabled: !busy,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '¿En qué le ayudo?',
              hintText: 'Por ejemplo: proponga una rutina breve de lectura',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('assistant-consult'),
            onPressed: busy ? null : controller.consult,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(
              controller.loading.value ? 'Consultando…' : 'Consultar asistente',
            ),
          ),
          if (controller.loading.value)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Consultando al asistente',
                ),
              ),
            ),
          MensajeOperacion(controller.error.value, error: true),
          MensajeOperacion(controller.feedback.value),
          if (response != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      draft == null
                          ? 'Una idea para usted'
                          : 'Propuesta para su rutina',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(response.mensaje),
                    if (draft != null) ...[
                      const Divider(height: 32),
                      Text(
                        draft.titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(draft.descripcion),
                      const SizedBox(height: 8),
                      Text(
                        '${categorias[draft.categoria]} · ${frecuencias[draft.frecuencia]} · ${tipos[draft.tipo]}',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Revise la propuesta. Se creará únicamente cuando la confirme.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('assistant-confirm'),
                        onPressed: controller.confirming.value
                            ? null
                            : controller.confirm,
                        child: Text(
                          controller.confirming.value
                              ? 'Guardando…'
                              : 'Confirmar y crear hábito',
                        ),
                      ),
                      TextButton(
                        key: const Key('assistant-cancel'),
                        onPressed: controller.confirming.value
                            ? null
                            : controller.discard,
                        child: const Text('Cancelar propuesta'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Las sugerencias son orientativas. Este asistente no ofrece consejos médicos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }),
  );
}
