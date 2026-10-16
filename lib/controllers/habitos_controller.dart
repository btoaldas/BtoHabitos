import 'dart:async';

import 'package:get/get.dart';

import '../models/models.dart';
import '../repositories/habitos_repository.dart';
import '../services/api_client.dart';
import '../services/session_authority.dart';
import 'session_controller.dart';

class HabitosController extends SessionController {
  HabitosController(super.sessions, this.repository) {
    bindSession();
  }
  final HabitosRepository repository;
  final items = <Habito>[].obs;
  final loading = false.obs, mutating = false.obs;
  final error = RxnString(),
      mutationError = RxnString(),
      feedback = RxnString();
  int _load = 0;
  int get completed => items.where((h) => h.datos.completado).length;

  @override
  void entered() => unawaited(load());
  @override
  void reset() {
    _load++;
    items.clear();
    loading.value = mutating.value = false;
    error.value = mutationError.value = feedback.value = null;
  }

  Future<void> load() async {
    final scope = capture();
    if (scope == null) return;
    final serial = ++_load;
    loading.value = true;
    error.value = null;
    try {
      final result = await repository.list(scope.identity);
      if (accepts(scope) && serial == _load) items.assignAll(result);
    } catch (e) {
      if (accepts(scope) && serial == _load) error.value = failureMessage(e);
    } finally {
      if (accepts(scope) && serial == _load) loading.value = false;
    }
  }

  void prepareForm() {
    mutationError.value = null;
    feedback.value = null;
  }

  Future<bool> _mutate(
    SessionIdentity identity,
    Future<Habito?> Function() action,
    String success, {
    int? removedId,
  }) async {
    final scope = capture();
    if (scope == null || !identical(identity, scope.identity)) return false;
    if (mutating.value) {
      mutationError.value = 'Espere a que termine la operación actual.';
      return false;
    }
    mutating.value = true;
    mutationError.value = feedback.value = null;
    ++_load;
    loading.value = false;
    try {
      final result = await action();
      if (!accepts(scope)) return false;
      ++_load;
      loading.value = false;
      if (removedId != null) {
        items.removeWhere((h) => h.id == removedId);
      } else if (result != null) {
        final index = items.indexWhere((h) => h.id == result.id);
        if (index < 0) {
          items.add(result);
        } else {
          items[index] = result;
        }
      }
      feedback.value = success;
      return true;
    } catch (e) {
      if (accepts(scope)) mutationError.value = failureMessage(e);
      return false;
    } finally {
      if (accepts(scope)) mutating.value = false;
    }
  }

  Future<bool> save(
    HabitoDraft draft, {
    int? id,
    required SessionIdentity identity,
  }) => _mutate(
    identity,
    () => repository.save(identity, draft, id: id),
    id == null ? 'Hábito creado.' : 'Cambios guardados.',
  );

  Future<bool> toggle(Habito habito, SessionIdentity identity) => _mutate(
    identity,
    () => repository.complete(identity, habito),
    habito.datos.completado
        ? 'Hábito reabierto.'
        : '¡Un paso más! Hábito completado.',
  );

  Future<bool> remove(Habito habito, SessionIdentity identity) => _mutate(
    identity,
    () async {
      await repository.remove(identity, habito.id);
      return null;
    },
    'Hábito eliminado.',
    removedId: habito.id,
  );
}
