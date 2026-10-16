import 'dart:async';

import 'package:bto_habitos/controllers/asistente_controller.dart';
import 'package:bto_habitos/controllers/auth_controller.dart';
import 'package:bto_habitos/controllers/catalogo_controller.dart';
import 'package:bto_habitos/controllers/habitos_controller.dart';
import 'package:bto_habitos/repositories/auth_repository.dart';
import 'package:bto_habitos/repositories/favoritos_repository.dart';
import 'package:bto_habitos/repositories/habitos_repository.dart';
import 'package:bto_habitos/screens/catalogo_screen.dart';
import 'package:bto_habitos/services/api_client.dart';
import 'package:bto_habitos/services/asistente_service.dart';
import 'package:bto_habitos/services/secure_token_storage.dart';
import 'package:bto_habitos/services/session_authority.dart';
import 'package:bto_habitos/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/widget_helpers.dart';

void main() {
  testWidgets('Catálogo carga, informa fallo, reintenta y muestra vacío', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f, login: true);
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/plantillas') {
        reached.complete();
        await release.future;
        return (status: 500, data: {'detail': 'fallo sintético'});
      }
      return f.backend.respond(o);
    };
    final pending = f.binding.catalogo.load();
    await pumpToBarrier(tester, reached);
    expect(find.text('Preparando su catálogo…'), findsOneWidget);
    release.complete();
    await pumpOperation(tester, pending);
    await settleOperations(tester);
    expect(find.text('El catálogo necesita un momento'), findsOneWidget);
    expectTouchTarget(tester, find.widgetWithText(FilledButton, 'Reintentar'));
    f.adapter.handler = null;
    f.backend.catalog = [];
    await tapVisible(tester, find.text('Reintentar'));
    expect(find.text('No hay plantillas disponibles'), findsOneWidget);
    f.backend.catalog = [
      {'id': 1, ...draftJson(titulo: 'Idea recuperada')},
    ];
    await tapVisible(tester, find.text('Reintentar'));
    expect(find.text('Idea recuperada'), findsOneWidget);
  });

  testWidgets('Mis hábitos muestra carga/error y recupera vacío y botón', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f, login: true);
    await tapVisible(tester, find.text('Mis hábitos'));
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/habitos') {
        reached.complete();
        await release.future;
        return (
          status: 422,
          data: {
            'detail': [
              {'msg': 'fallo sintético'},
            ],
          },
        );
      }
      return f.backend.respond(o);
    };
    final pending = f.binding.habitos.load();
    await pumpToBarrier(tester, reached);
    expect(find.text('Buscando sus hábitos…'), findsOneWidget);
    release.complete();
    await pumpOperation(tester, pending);
    await settleOperations(tester);
    expect(find.text('No pudimos cargar su rutina'), findsOneWidget);
    f.adapter.handler = null;
    await tapVisible(tester, find.text('Reintentar'));
    expect(find.text('Un pequeño paso cuenta'), findsOneWidget);
    expectTouchTarget(tester, find.byKey(const Key('habit-create')));
  });

  testWidgets('Asistente tiene carga/error/reintento y consejo sin alta', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f, login: true);
    await tapVisible(tester, find.text('Asistente'));
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/asistente') {
        reached.complete();
        await release.future;
        return (status: 503, data: {'detail': 'fallo sintético'});
      }
      return f.backend.respond(o);
    };
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Una idea',
    );
    await tester.tap(find.byKey(const Key('assistant-consult')));
    await pumpToBarrier(tester, reached);
    expect(find.text('Consultando…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('assistant-consult')))
          .onPressed,
      isNull,
    );
    release.complete();
    await settleOperations(tester);
    expect(find.textContaining('no está disponible'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('assistant-consult')))
          .onPressed,
      isNotNull,
    );
    f.adapter.handler = null;
    f.backend.assistant = {
      'tipo': 'consejo',
      'mensaje': 'Planifique un paso sencillo.',
    };
    await tapVisible(tester, find.byKey(const Key('assistant-consult')));
    expect(find.text('Planifique un paso sencillo.'), findsOneWidget);
    expect(find.byKey(const Key('assistant-confirm')), findsNothing);
    expect(f.adapter.matching('POST', '/habitos'), isEmpty);
  });

  testWidgets(
    'favoritos informa fallo de disco y abre de nuevo al reintentar',
    (tester) async {
      // Inyección de un almacenamiento que falla de verdad, sin lógica por etiqueta.
      final sessions = SessionAuthority(), driver = MemorySecureDriver();
      final backend = FixtureBackend();
      final adapter = FixtureAdapter(backend);
      final dio = Dio(BaseOptions(baseUrl: 'http://fixture.invalid'))
        ..httpClientAdapter = adapter;
      final api = ApiClient(
        sessions: sessions,
        tokens: SecureTokenStorage(driver),
        dio: dio,
      );
      final auth = AuthController(
        AuthRepository(api),
        SecureTokenStorage(driver),
        sessions,
      );
      final hub = FavoritesCoordinator(), memory = MemoryFavorites();
      var failOpen = true;
      final favorites = FavoritosRepository(
        coordinator: hub,
        open: (name) async {
          if (failOpen) throw StateError('disco no disponible');
          return memory.open(name);
        },
      );
      final catalog = CatalogoController(
        sessions,
        CatalogoRepository(api),
        favorites,
      );
      final habits = HabitosController(sessions, HabitosRepository(api));
      final assistant = AsistenteController(
        sessions,
        AsistenteService(api),
        habits,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        assistant.onClose();
        habits.onClose();
        catalog.onClose();
        auth.onClose();
        await pumpOperation(tester, hub.queue.run(() async {}));
        dio.close();
      });
      await pumpOperation(
        tester,
        auth.authenticate('persona1@example.test', 'Solo-Prueba-123'),
      );
      await pumpOperation(tester, catalog.load());
      await pumpOperation(tester, hub.queue.run(() async {}));
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: Scaffold(
            body: CatalogoScreen(
              controller: catalog,
              habitos: habits,
              identity: sessions.current.value!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No se pudieron abrir'), findsOneWidget);
      failOpen = false;
      await tapVisible(tester, find.text('Reintentar favoritos'));
      await pumpOperation(tester, hub.queue.run(() async {}));
      await tester.pumpAndSettle();
      expect(catalog.favoritesLoading.value, isFalse);
      await tapVisible(tester, find.byKey(const Key('favorite-1')));
      await pumpOperation(tester, hub.queue.run(() async {}));
      await tester.pumpAndSettle();
      expect(catalog.favoriteIds, {1});
    },
  );
}
