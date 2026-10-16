import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/asistente_service.dart';
import 'habitos_controller.dart';
import 'session_controller.dart';

class AsistenteController extends SessionController {
  AsistenteController(super.sessions, this.service, this.habitos) {
    bindSession();
  }
  final AsistenteService service;
  final HabitosController habitos;
  final input = TextEditingController();
  final reply = Rxn<RespuestaAsistente>();
  final error = RxnString(), feedback = RxnString();
  final loading = false.obs, confirming = false.obs;
  OperationScope? _proposalScope;
  int _interaction = 0;
  bool _consumed = false;

  @override
  void reset() => discard();

  void discard() {
    ++_interaction;
    _proposalScope = null;
    _consumed = false;
    reply.value = null;
    error.value = feedback.value = null;
    loading.value = confirming.value = false;
    input.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> consult() async {
    final scope = capture();
    if (scope == null || loading.value || confirming.value) return;
    final consulta = input.text.trim();
    if (consulta.isEmpty || consulta.length > 1000) {
      error.value = 'Escriba una consulta de 1 a 1000 caracteres.';
      return;
    }
    final interaction = ++_interaction;
    loading.value = true;
    reply.value = null;
    _proposalScope = null;
    _consumed = false;
    error.value = feedback.value = null;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final result = await service.consult(scope.identity, consulta);
      if (!accepts(scope) || interaction != _interaction) return;
      reply.value = result;
      if (result.propuesta != null) _proposalScope = scope;
    } catch (e) {
      if (accepts(scope) && interaction == _interaction) {
        error.value = failureMessage(e);
      }
    } finally {
      if (accepts(scope) && interaction == _interaction) loading.value = false;
    }
  }

  Future<void> confirm() async {
    final scope = _proposalScope;
    final draft = reply.value?.propuesta;
    if (scope == null || draft == null || _consumed || !accepts(scope)) return;
    _consumed = true; // Síncrono: dos toques producen una sola llamada.
    confirming.value = true;
    error.value = null;
    final interaction = _interaction;
    try {
      final saved = await habitos.save(draft, identity: scope.identity);
      if (!accepts(scope) || interaction != _interaction) return;
      if (saved) {
        reply.value = null;
        _proposalScope = null;
        input.clear();
        feedback.value = 'Propuesta guardada en Mis hábitos.';
      } else {
        error.value =
            habitos.mutationError.value ??
            'No se pudo guardar. Inténtelo de nuevo.';
        _consumed = false;
      }
    } finally {
      if (accepts(scope) && interaction == _interaction) {
        confirming.value = false;
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    input.dispose();
  }
}
