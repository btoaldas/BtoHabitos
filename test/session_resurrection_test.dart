import 'dart:async';

import 'package:bto_habitos/controllers/auth_controller.dart';
import 'package:bto_habitos/repositories/auth_repository.dart';
import 'package:bto_habitos/services/api_client.dart';
import 'package:bto_habitos/services/secure_token_storage.dart';
import 'package:bto_habitos/services/session_authority.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

class _Barrier {
  final reached = Completer<void>();
  final released = Completer<void>();

  Future<void> hold() async {
    reached.complete();
    await released.future;
  }

  void release() {
    if (!released.isCompleted) released.complete();
  }
}

/// Solo autenticación: sin bindings, favoritos ni cierres dobles de controllers.
class _AuthHarness {
  _AuthHarness({MemorySecureDriver? driver})
    : driver = driver ?? MemorySecureDriver() {
    adapter = FixtureAdapter(FixtureBackend());
    dio = Dio(BaseOptions(baseUrl: 'http://fixture.invalid'))
      ..httpClientAdapter = adapter;
    tokens = SecureTokenStorage(this.driver);
    api = ApiClient(sessions: sessions, tokens: tokens, dio: dio);
  }

  final MemorySecureDriver driver;
  final sessions = SessionAuthority();
  final controllers = <AuthController>[];
  final barriers = <_Barrier>[];
  final pending = <Future<dynamic>>[];
  late final FixtureAdapter adapter;
  late final Dio dio;
  late final SecureTokenStorage tokens;
  late final ApiClient api;

  AuthController controller() {
    final controller = AuthController(
      AuthRepository(api),
      SecureTokenStorage(driver),
      sessions,
    );
    controllers.add(controller);
    return controller;
  }

  _Barrier barrier() {
    final barrier = _Barrier();
    barriers.add(barrier);
    return barrier;
  }

  Future<T> track<T>(Future<T> operation) {
    pending.add(operation);
    return operation;
  }

  Future<void> login(AuthController controller, [int id = 1]) => track(
    controller.authenticate('persona$id@example.test', 'Solo-Prueba-123'),
  );

  void closeController(AuthController controller) {
    if (!controllers.remove(controller)) {
      throw StateError('El controller ya se cerró');
    }
    controller.onClose();
  }

  Future<void> dispose() async {
    for (final barrier in barriers) {
      barrier.release();
    }
    await Future.wait(pending);
    for (final controller in controllers.toList()) {
      closeController(controller);
    }
    await tokens.read(); // Drena también operaciones no esperadas del cliente.
    dio.close(force: true);
  }

  // Un arranque nuevo no comparte tickets, cola pendiente ni estado del driver.
  _AuthHarness reload() =>
      _AuthHarness(driver: MemorySecureDriver()..value = driver.value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _AuthHarness h;
  setUp(() => h = _AuthHarness());
  tearDown(() => h.dispose());

  test('logout A en cola no permite que restore B resucite A', () async {
    final a = h.controller();
    await h.login(a);
    expect(h.driver.value, 'fixture-access-1');
    final barrier = h.barrier();
    h.driver.beforeRead = () async {
      h.driver.beforeRead = null;
      await barrier.hold();
    };
    final previousRead = h.track(h.tokens.read());
    await barrier.reached.future;

    final logout = h.track(a.logout());
    expect(h.sessions.current.value, isNull);
    final b = h.controller();
    final restore = h.track(b.restore());
    barrier.release();
    await Future.wait<dynamic>([previousRead, logout, restore]);

    final beforeReload = (
      user: h.sessions.current.value?.usuario.id,
      tokenRemoved: h.driver.value == null,
      meRequests: h.adapter.matching('GET', '/auth/me').length,
    );
    final reloaded = h.reload();
    addTearDown(reloaded.dispose);
    await reloaded.track(reloaded.controller().restore());
    expect(
      (
        before: beforeReload,
        after: (
          user: reloaded.sessions.current.value?.usuario.id,
          tokenRemoved: reloaded.driver.value == null,
          meRequests: reloaded.adapter.matching('GET', '/auth/me').length,
        ),
      ),
      (
        before: (user: null, tokenRemoved: true, meRequests: 0),
        after: (user: null, tokenRemoved: true, meRequests: 0),
      ),
    );
  });

  test(
    'write A nativo retenido no se restaura desde B tras cerrar A',
    () async {
      final a = h.controller();
      final barrier = h.barrier();
      h.driver.beforeWrite = () async {
        h.driver.beforeWrite = null;
        await barrier.hold();
      };
      final loginA = h.login(a);
      await barrier.reached.future;
      expect(h.driver.writes, 1); // La escritura ya entró al driver nativo.
      final b = h.controller();
      final restoreB = h.track(b.restore());
      h.closeController(a);
      barrier.release();
      await Future.wait([loginA, restoreB]);

      final beforeReload = (
        user: h.sessions.current.value?.usuario.id,
        tokenRemoved: h.driver.value == null,
        meRequests: h.adapter.matching('GET', '/auth/me').length,
      );
      final reloaded = h.reload();
      addTearDown(reloaded.dispose);
      await reloaded.track(reloaded.controller().restore());
      expect(
        (
          before: beforeReload,
          after: (
            user: reloaded.sessions.current.value?.usuario.id,
            tokenRemoved: reloaded.driver.value == null,
            meRequests: reloaded.adapter.matching('GET', '/auth/me').length,
          ),
        ),
        (
          before: (user: null, tokenRemoved: true, meRequests: 0),
          after: (user: null, tokenRemoved: true, meRequests: 0),
        ),
      );
    },
  );

  test('logout A y login B durante write A nativo conservan B', () async {
    final a = h.controller();
    final barrier = h.barrier();
    h.driver.beforeWrite = () async {
      h.driver.beforeWrite = null;
      await barrier.hold();
    };
    final loginA = h.login(a);
    await barrier.reached.future;
    final logoutA = h.track(a.logout());
    expect(h.sessions.current.value, isNull);
    final b = h.controller();
    final loginB = h.login(b, 2);
    barrier.release();
    await Future.wait([loginA, logoutA, loginB]);

    expect(h.sessions.current.value?.usuario.id, 2);
    expect(h.driver.value, 'fixture-access-2');
    final reloaded = h.reload();
    addTearDown(reloaded.dispose);
    await reloaded.track(reloaded.controller().restore());
    expect(reloaded.sessions.current.value?.usuario.id, 2);
    expect(reloaded.driver.value, 'fixture-access-2');
  });

  test(
    'dos restores concurrentes solo publican el último controller',
    () async {
      h.driver.value = 'fixture-access-1';
      final a = h.controller();
      final barrier = h.barrier();
      h.driver.beforeRead = () async {
        h.driver.beforeRead = null;
        await barrier.hold();
      };
      final restoreA = h.track(a.restore());
      await barrier.reached.future;
      final b = h.controller();
      final restoreB = h.track(b.restore());
      barrier.release();
      await Future.wait([restoreA, restoreB]);

      expect(h.adapter.matching('GET', '/auth/me'), hasLength(1));
      expect(h.sessions.current.value?.usuario.id, 1);
      expect(h.driver.value, 'fixture-access-1');
      expect(b.restoring.value, isFalse);
      h.closeController(a);
      expect(h.sessions.current.value?.usuario.id, 1);
    },
  );

  test('401 en vuelo desde A no cierra ni retira la credencial de B', () async {
    final a = h.controller();
    await h.login(a);
    final identityA = h.sessions.current.value!;
    final barrier = h.barrier();
    h.adapter.handler = (options) async {
      await barrier.hold();
      return (status: 401, data: {'detail': 'expirada'});
    };
    final oldResponse = h.track(
      expectLater(
        h.api.request('GET', '/habitos', identity: identityA),
        throwsA(isA<AppFailure>().having((e) => e.status, 'status', 401)),
      ),
    );
    await barrier.reached.future;
    // Solo la petición antigua usa el handler retenido.
    h.adapter.handler = null;
    await h.track(a.logout());
    final b = h.controller();
    await h.login(b, 2);
    final deletesBefore401 = h.driver.deletes;
    barrier.release();
    await oldResponse;
    await h.tokens.read();

    expect(h.sessions.current.value?.usuario.id, 2);
    expect(h.driver.value, 'fixture-access-2');
    expect(h.driver.deletes, deletesBefore401);
    expect(
      h.adapter.matching('GET', '/habitos').single.headers['Authorization'],
      'Bearer fixture-access-1',
    );
  });

  // Trasladadas de auth_controller_test: conservan las aserciones de R1,
  // usando un solo dueño del cierre y drenaje explícito de todas las colas.
  test(
    'onClose antiguo no invalida nuevo controller con escritura en cola',
    () async {
      h.driver.value = 'fixture-access-1';
      final barrier = h.barrier();
      h.driver.beforeRead = () async {
        h.driver.beforeRead = null;
        await barrier.hold();
      };
      final a = h.controller();
      final oldRestore = h.track(a.restore());
      await barrier.reached.future;
      final b = h.controller();
      final entering = h.login(b, 2);
      h.closeController(a);
      barrier.release();
      await Future.wait([oldRestore, entering]);
      expect(h.sessions.current.value?.usuario.id, 2);
      expect(h.driver.value, 'fixture-access-2');
    },
  );

  test(
    'dos auth controllers con escritura A en vuelo terminan almacenando B',
    () async {
      final barrier = h.barrier();
      h.driver.beforeWrite = () async {
        h.driver.beforeWrite = null;
        await barrier.hold();
      };
      final a = h.controller();
      final old = h.login(a);
      await barrier.reached.future;
      final b = h.controller();
      final loginB = h.login(b, 2);
      expect(h.sessions.current.value, isNull);
      barrier.release();
      await Future.wait([old, loginB]);
      expect(h.sessions.current.value?.usuario.id, 2);
      expect(h.driver.value, 'fixture-access-2');
      h.closeController(a);
      expect(h.sessions.current.value?.usuario.id, 2);
    },
  );
}
