import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'estado_operacion.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.auth, required this.register});
  final AuthController auth;
  final bool register;
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  bool _obscure = true;

  void _submit() {
    if (_form.currentState!.validate() && !widget.auth.busy.value) {
      widget.auth.submit(register: widget.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.spa_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BtoHábitos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pequeños pasos. Una rutina propia.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _form,
                        child: Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.register
                                    ? 'Crear su cuenta'
                                    : 'Qué bueno volver',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('auth-email'),
                                controller: auth.emailInput,
                                enabled: !auth.busy.value,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (v) =>
                                    v != null &&
                                        v.trim().length <= 254 &&
                                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch(v.trim())
                                    ? null
                                    : 'Ingrese un correo válido.',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('auth-password'),
                                controller: auth.passwordInput,
                                enabled: !auth.busy.value,
                                obscureText: _obscure,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: [
                                  widget.register
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: widget.register
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!widget.register) _submit();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  helperText: 'Entre 8 y 128 caracteres',
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    v != null &&
                                        v.length >= 8 &&
                                        v.length <= 128
                                    ? null
                                    : 'Use entre 8 y 128 caracteres.',
                              ),
                              if (widget.register) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('auth-confirmation'),
                                  controller: auth.confirmationInput,
                                  enabled: !auth.busy.value,
                                  obscureText: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Repetir contraseña',
                                  ),
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) => v == auth.passwordInput.text
                                      ? null
                                      : 'Las contraseñas no coinciden.',
                                ),
                              ],
                              MensajeOperacion(auth.error.value, error: true),
                              MensajeOperacion(auth.message.value),
                              const SizedBox(height: 16),
                              FilledButton(
                                key: const Key('auth-submit'),
                                onPressed: auth.busy.value ? null : _submit,
                                child: Text(
                                  auth.busy.value
                                      ? 'Un momento…'
                                      : widget.register
                                      ? 'Crear cuenta'
                                      : 'Iniciar sesión',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: auth.busy.value
                                    ? null
                                    : () => auth.showRegistration(
                                        !widget.register,
                                      ),
                                child: Text(
                                  widget.register
                                      ? 'Ya tengo cuenta'
                                      : 'Crear una cuenta',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
