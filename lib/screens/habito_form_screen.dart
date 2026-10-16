import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/habitos_controller.dart';
import '../models/models.dart';
import '../services/session_authority.dart';
import '../widgets/estado_operacion.dart';

class HabitoFormScreen extends StatefulWidget {
  const HabitoFormScreen({
    super.key,
    required this.controller,
    required this.identity,
    this.initial,
    this.id,
  });
  final HabitosController controller;
  final SessionIdentity identity;
  final HabitoDraft? initial;
  final int? id;
  @override
  State<HabitoFormScreen> createState() => _HabitoFormScreenState();
}

class _HabitoFormScreenState extends State<HabitoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _titulo, _descripcion;
  late String _categoria, _frecuencia, _tipo;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? const HabitoDraft(titulo: '');
    _titulo = TextEditingController(text: initial.titulo);
    _descripcion = TextEditingController(text: initial.descripcion);
    _categoria = initial.categoria;
    _frecuencia = initial.frecuencia;
    _tipo = initial.tipo;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await widget.controller.save(
      HabitoDraft(
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim(),
        categoria: _categoria,
        frecuencia: _frecuencia,
        tipo: _tipo,
        plantillaId: widget.initial?.plantillaId,
        completado: widget.initial?.completado ?? false,
      ),
      id: widget.id,
      identity: widget.identity,
    );
    if (mounted && saved) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Widget _select(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> update,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList(),
    onChanged: (v) {
      if (v != null) setState(() => update(v));
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.id == null ? 'Nuevo hábito' : 'Editar hábito'),
    ),
    body: ContenidoPagina(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Dé el siguiente paso a su manera.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('habit-title'),
              controller: _titulo,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escriba un título.'
                  : v.trim().length > 100
                  ? 'Máximo 100 caracteres.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('habit-description'),
              controller: _descripcion,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
              validator: (v) =>
                  (v?.length ?? 0) > 500 ? 'Máximo 500 caracteres.' : null,
            ),
            const SizedBox(height: 16),
            _select('Categoría', _categoria, categorias, (v) => _categoria = v),
            const SizedBox(height: 16),
            _select(
              'Frecuencia',
              _frecuencia,
              frecuencias,
              (v) => _frecuencia = v,
            ),
            const SizedBox(height: 16),
            _select('Tipo', _tipo, tipos, (v) => _tipo = v),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MensajeOperacion(
                    widget.controller.mutationError.value,
                    error: true,
                  ),
                  FilledButton.icon(
                    key: const Key('habit-save'),
                    onPressed: widget.controller.mutating.value ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      widget.controller.mutating.value
                          ? 'Guardando…'
                          : 'Guardar hábito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> openHabitoForm(
  BuildContext context,
  HabitosController controller,
  SessionIdentity identity, {
  HabitoDraft? initial,
  int? id,
}) async {
  if (!controller.sessions.isCurrent(identity)) return;
  controller.prepareForm();
  await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => HabitoFormScreen(
        controller: controller,
        identity: identity,
        initial: initial,
        id: id,
      ),
    ),
  );
}
