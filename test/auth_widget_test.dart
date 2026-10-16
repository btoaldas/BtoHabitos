import 'dart:async';

import 'package:bto_habitos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/widget_helpers.dart';

void main() {
  testWidgets(
    'login valida y limpia clave/correo/teclado antes de esperar API',
    (tester) async {
      final f = Fixture();
      await mountFixture(tester, f);
      expectTouchTarget(tester, find.byKey(const Key('auth-submit')));
      await tapVisible(tester, find.text('Iniciar sesión'));
      expect(find.text('Ingrese un correo válido.'), findsOneWidget);
      expect(f.adapter.matching('POST', '/auth/login'), isEmpty);
      await tester.enterText(
        find.byKey(const Key('auth-email')),
        'persona1@example.test',
      );
      await tester.enterText(
        find.byKey(const Key('auth-password')),
        'Solo-Prueba-123',
      );
      final reached = Completer<void>(), release = Completer<void>();
      f.adapter.handler = (o) async {
        if (o.path == '/auth/login') {
          reached.complete();
          await release.future;
        }
        return f.backend.respond(o);
      };
      await tester.tap(find.byKey(const Key('auth-submit')));
      await pumpToBarrier(tester, reached);
      expect(f.binding.auth.passwordInput.text, isEmpty);
      expect(f.binding.auth.emailInput.text, isEmpty);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(f.binding.auth.busy.value, isTrue);
      release.complete();
      await settleOperations(tester);
      expect(find.text('Catálogo'), findsOneWidget);
      expect(find.text('Mis hábitos'), findsOneWidget);
      expect(find.text('Asistente'), findsOneWidget);
      expect(find.textContaining('21 plantillas'), findsOneWidget);
    },
  );

  testWidgets(
    'registro valida repetición y confirma creación antes del acceso',
    (tester) async {
      final f = Fixture();
      await mountFixture(tester, f);
      await tapVisible(tester, find.text('Crear una cuenta'));
      await tester.enterText(
        find.byKey(const Key('auth-email')),
        'persona3@example.test',
      );
      await tester.enterText(
        find.byKey(const Key('auth-password')),
        'Solo-Prueba-123',
      );
      await tester.enterText(
        find.byKey(const Key('auth-confirmation')),
        'No-Coincide',
      );
      await tapVisible(tester, find.text('Crear cuenta'));
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(f.adapter.matching('POST', '/auth/register'), isEmpty);
      await tester.enterText(
        find.byKey(const Key('auth-confirmation')),
        'Solo-Prueba-123',
      );
      await tapVisible(tester, find.text('Crear cuenta'));
      expect(f.adapter.matching('POST', '/auth/register'), hasLength(1));
      expect(
        find.text('Cuenta creada. Ya puede iniciar sesión.'),
        findsOneWidget,
      );
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(f.binding.auth.passwordInput.text, isEmpty);
      expect(f.binding.auth.confirmationInput.text, isEmpty);
    },
  );

  testWidgets('login fallido informa y recupera el botón', (tester) async {
    final f = Fixture();
    await mountFixture(tester, f);
    f.adapter.handler = (o) async =>
        (status: 401, data: {'detail': 'credenciales inválidas'});
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'persona1@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'Solo-Prueba-123',
    );
    await tapVisible(tester, find.text('Iniciar sesión'));
    expect(find.textContaining('Inicie sesión de nuevo'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('auth-submit')))
          .onPressed,
      isNotNull,
    );
    expect(f.binding.auth.passwordInput.text, isEmpty);
    f.adapter.handler = null;
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'persona1@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'Solo-Prueba-123',
    );
    await tapVisible(tester, find.text('Iniciar sesión'));
    expect(find.text('Catálogo'), findsOneWidget);
  });

  testWidgets('logout limpia datos y teclado del asistente', (tester) async {
    final f = Fixture();
    await mountFixture(tester, f, login: true);
    await tapVisible(tester, find.text('Asistente'));
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Una consulta sintética',
    );
    expect(tester.testTextInput.isVisible, isTrue);
    await tapVisible(tester, find.byKey(const Key('logout')));
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    expect(f.binding.asistente.input.text, isEmpty);
    expect(f.binding.auth.emailInput.text, isEmpty);
    expect(f.binding.auth.passwordInput.text, isEmpty);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(f.secure.value, isNull);
  });

  testWidgets('401 desde formulario privado retira ruta y deja acceso vacío', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f, login: true);
    await tapVisible(tester, find.text('Mis hábitos'));
    await tapVisible(tester, find.byKey(const Key('habit-create')));
    await tester.enterText(find.byKey(const Key('habit-title')), 'Lectura');
    f.adapter.handler = (o) async => o.path == '/habitos' && o.method == 'POST'
        ? (status: 401, data: {'detail': 'expirada'})
        : f.backend.respond(o);
    await tapVisible(tester, find.byKey(const Key('habit-save')));
    expect(find.text('Nuevo hábito'), findsNothing);
    expect(find.byKey(const Key('auth-password')), findsOneWidget);
    expect(f.binding.auth.passwordInput.text, isEmpty);
    expect(f.binding.habitos.items, isEmpty);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('restauración recuperable muestra reintento sin perder token', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f);
    f.secure.value = 'fixture-access-1';
    f.adapter.handler = (o) async =>
        (status: 503, data: {'detail': 'no disponible'});
    await pumpOperation(tester, f.binding.auth.restore());
    await settleOperations(tester);
    expect(find.text('No pudimos comprobar su sesión'), findsOneWidget);
    expect(f.secure.value, 'fixture-access-1');
    f.adapter.handler = null;
    await tapVisible(tester, find.text('Reintentar'));
    expect(find.text('Catálogo'), findsOneWidget);
  });

  testWidgets('pantalla de restauración muestra carga real', (tester) async {
    final f = Fixture();
    await mountFixture(tester, f);
    final reached = Completer<void>(), release = Completer<void>();
    f.secure.beforeRead = () async {
      reached.complete();
      await release.future;
    };
    final pending = f.binding.auth.restore();
    await pumpToBarrier(tester, reached);
    expect(find.text('Recuperando su sesión…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    release.complete();
    await pumpOperation(tester, pending);
    await settleOperations(tester);
    expect(find.byKey(const Key('auth-submit')), findsOneWidget);
  });

  testWidgets('acceso cabe en pantalla móvil y con texto aumentado', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f);
    tester.view.physicalSize = const Size(360, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(BtoHabitosApp(binding: f.binding));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const Key('auth-submit'))),
      ).scale(10),
      15,
    );
    expect(tester.takeException(), isNull);
    expectTouchTarget(tester, find.byKey(const Key('auth-submit')));
  });
}
