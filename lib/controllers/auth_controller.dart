import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../services/secure_token_storage.dart';
import '../services/session_authority.dart';

class AuthController extends GetxController {
  AuthController(this.repository, this.tokens, this.sessions) {
    _sessionWorker = ever(sessions.current, (value) {
      if (value == null) {
        clearInputs();
        if (sessions.notice != null) {
          registerMode.value = false;
          message.value = sessions.notice;
        }
      }
    });
  }
  final AuthRepository repository;
  final SecureTokenStorage tokens;
  final SessionAuthority sessions;
  final emailInput = TextEditingController();
  final passwordInput = TextEditingController();
  final confirmationInput = TextEditingController();
  final busy = false.obs, restoring = false.obs, registerMode = false.obs;
  final error = RxnString(), restoreError = RxnString(), message = RxnString();
  final _owner = Object();
  bool _alive = true;
  late final Worker _sessionWorker;

  bool _valid(SessionTicket ticket) => _alive && sessions.accepts(ticket);

  void clearInputs() {
    emailInput.clear();
    passwordInput.clear();
    confirmationInput.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void showRegistration(bool value) {
    if (busy.value) return;
    clearInputs();
    error.value = null;
    message.value = null;
    registerMode.value = value;
  }

  Future<void> restore() async {
    final ticket = sessions.begin(_owner);
    restoring.value = true;
    busy.value = false;
    restoreError.value = null;
    clearInputs();
    try {
      final originalToken = await tokens.read();
      if (!_valid(ticket) || originalToken == null) return;
      final usuario = await repository.me(originalToken);
      if (_valid(ticket)) sessions.publish(ticket, originalToken, usuario);
    } catch (e) {
      if (!_valid(ticket)) return;
      if (e is AppFailure && e.status == 401) {
        message.value = 'Su sesión expiró. Inicie sesión de nuevo.';
        await tokens.clear(() => _valid(ticket));
      } else {
        // Una caída de red no elimina un token que podría seguir siendo válido.
        restoreError.value = failureMessage(e);
      }
    } finally {
      if (_valid(ticket)) restoring.value = false;
    }
  }

  Future<void> submit({required bool register}) {
    final email = emailInput.text.trim().toLowerCase();
    final password = passwordInput.text;
    clearInputs(); // La clave sale del formulario antes del primer await.
    return authenticate(email, password, register: register);
  }

  Future<void> authenticate(
    String email,
    String password, {
    bool register = false,
  }) async {
    if (!_alive || busy.value) return;
    final ticket = sessions.begin(_owner);
    restoring.value = false;
    restoreError.value = null;
    error.value = null;
    message.value = null;
    busy.value = true;
    clearInputs();
    try {
      await tokens.clear(() => _valid(ticket));
      if (!_valid(ticket)) return;
      if (register) {
        await repository.register(email, password);
        if (!_valid(ticket)) return;
        registerMode.value = false;
        message.value = 'Cuenta creada. Ya puede iniciar sesión.';
      } else {
        final acceso = await repository.login(email, password);
        if (!_valid(ticket)) return;
        await tokens.write(acceso.token, () => _valid(ticket));
        if (_valid(ticket)) {
          sessions.publish(ticket, acceso.token, acceso.usuario);
        }
      }
    } catch (e) {
      if (_valid(ticket)) error.value = failureMessage(e);
    } finally {
      if (_valid(ticket)) busy.value = false;
    }
  }

  Future<void> logout() async {
    if (!_alive || !sessions.owns(_owner)) return;
    final ticket = sessions.begin(_owner);
    clearInputs();
    busy.value = false;
    restoring.value = false;
    error.value = null;
    restoreError.value = null;
    registerMode.value = false;
    try {
      await tokens.clear(() => _valid(ticket));
    } catch (_) {
      if (_valid(ticket)) {
        error.value = 'No se pudo retirar la sesión del dispositivo. Reintente cerrar sesión.';
      }
    }
  }

  @override
  void onClose() {
    if (!_alive) return;
    _alive = false;
    if (sessions.owns(_owner)) sessions.begin(_owner);
    _sessionWorker.dispose();
    clearInputs();
    emailInput.dispose();
    passwordInput.dispose();
    confirmationInput.dispose();
    super.onClose();
  }
}
