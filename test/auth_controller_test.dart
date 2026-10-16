import 'dart:async';

import 'package:bto_habitos/controllers/auth_controller.dart';
import 'package:bto_habitos/repositories/auth_repository.dart';
import 'package:bto_habitos/services/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Fixture f;
  setUp(() {
    f = Fixture();
  });
  tearDown(() => f.close());

  test('restaura con auth/me y conserva la sesión comprobada', () async {
    f.secure.value = 'fixture-access-1';
    await f.binding.auth.restore();
    expect(f.sessions.current.value?.usuario.id, 1);
    expect(f.adapter.matching('GET', '/auth/me'), hasLength(1));
    expect(f.secure.value, 'fixture-access-1');
    expect(f.binding.auth.restoring.value, isFalse);
  });

  test(
    'lectura retenida de restauración no revive tras logout y login B',
    () async {
      f.secure.value = 'fixture-access-1';
      final reached = Completer<void>(), release = Completer<void>();
      f.secure.beforeRead = () async {
        reached.complete();
        await release.future;
      };
      final restoring = f.binding.auth.restore();
      await reached.future;
      final logout = f.binding.auth.logout();
      final loginB = f.login(2);
      expect(f.sessions.current.value, isNull);
      release.complete();
      await Future.wait([restoring, logout, loginB]);
      expect(f.sessions.current.value?.usuario.id, 2);
      expect(f.secure.value, 'fixture-access-2');
      expect(f.adapter.matching('GET', '/auth/me'), isEmpty);
    },
  );

  test('auth/me tardío no publica A encima de B', () async {
    f.secure.value = 'fixture-access-1';
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/auth/me') {
        reached.complete();
        await release.future;
      }
      return f.backend.respond(o);
    };
    final restoring = f.binding.auth.restore();
    await reached.future;
    await f.binding.auth.logout();
    await f.login(2);
    release.complete();
    await restoring;
    expect(f.sessions.current.value?.usuario.id, 2);
    expect(f.secure.value, 'fixture-access-2');
  });

  test(
    'fallo de red al restaurar conserva token y permite reintento',
    () async {
      f.secure.value = 'fixture-access-1';
      f.adapter.handler = (o) async =>
          (status: 500, data: {'detail': 'fallo sintético'});
      await f.binding.auth.restore();
      expect(f.secure.value, 'fixture-access-1');
      expect(f.binding.auth.restoreError.value, isNotNull);
      expect(f.binding.auth.restoring.value, isFalse);
      f.adapter.handler = null;
      await f.binding.auth.restore();
      expect(f.sessions.current.value?.usuario.id, 1);
      expect(f.binding.auth.restoreError.value, isNull);
    },
  );

  test('401 al restaurar retira solo el token inválido', () async {
    f.secure.value = 'fixture-access-1';
    f.adapter.handler = (o) async =>
        (status: 401, data: {'detail': 'expirada'});
    await f.binding.auth.restore();
    expect(f.secure.value, isNull);
    expect(f.sessions.current.value, isNull);
    expect(f.binding.auth.message.value, contains('expiró'));
    expect(f.binding.auth.restoring.value, isFalse);
  });

  test(
    'registro usa contrato sin guardar contraseña y vuelve al login',
    () async {
      f.binding.auth.showRegistration(true);
      f.binding.auth.emailInput.text = 'persona3@example.test';
      f.binding.auth.passwordInput.text = 'Solo-Prueba-123';
      f.binding.auth.confirmationInput.text = 'Solo-Prueba-123';
      await f.binding.auth.submit(register: true);
      expect(f.adapter.matching('POST', '/auth/register'), hasLength(1));
      expect(f.binding.auth.passwordInput.text, isEmpty);
      expect(f.binding.auth.emailInput.text, isEmpty);
      expect(f.binding.auth.confirmationInput.text, isEmpty);
      expect(f.binding.auth.registerMode.value, isFalse);
      expect(f.binding.auth.message.value, contains('Cuenta creada'));
      expect(f.secure.value, isNull);
    },
  );

  test(
    'onClose antiguo no invalida nuevo controller con escritura en cola',
    () async {
      final reached = Completer<void>(), release = Completer<void>();
      f.secure.value = 'fixture-access-1';
      f.secure.beforeRead = () async {
        reached.complete();
        await release.future;
      };
      final oldRestore = f.binding.auth.restore();
      await reached.future;
      final newer = AuthController(
        AuthRepository(f.binding.api),
        SecureTokenStorage(f.secure),
        f.sessions,
      );
      final entering = newer.authenticate(
        'persona2@example.test',
        'Solo-Prueba-123',
      );
      f.binding.auth.onClose();
      release.complete();
      await Future.wait([oldRestore, entering]);
      expect(f.sessions.current.value?.usuario.id, 2);
      expect(f.secure.value, 'fixture-access-2');
      // La fixture conserva el resto del grafo; el controller ya cerrado no se cierra dos veces.
      newer.onClose();
    },
  );

  test(
    '401 antiguo no cierra B y cada petición conserva el token original',
    () async {
      await f.login();
      await f.ready();
      final original = f.sessions.current.value!;
      final reached = Completer<void>(), release = Completer<void>();
      f.adapter.handler = (o) async {
        if (o.path == '/habitos' &&
            o.headers['Authorization'] == 'Bearer ${original.token}') {
          reached.complete();
          await release.future;
          return (status: 401, data: {'detail': 'expirada'});
        }
        return f.backend.respond(o);
      };
      final old = f.binding.habitos.load();
      await reached.future;
      await f.binding.auth.logout();
      await f.login(2);
      await f.ready();
      release.complete();
      await old;
      expect(f.sessions.current.value?.usuario.id, 2);
      expect(f.secure.value, 'fixture-access-2');
      expect(f.binding.habitos.error.value, isNull);
      final captured = f.adapter.matching('GET', '/habitos');
      expect(
        captured.any(
          (o) => o.headers['Authorization'] == 'Bearer fixture-access-1',
        ),
        isTrue,
      );
      expect(captured.last.headers['Authorization'], 'Bearer fixture-access-2');
    },
  );

  test('interceptor demorado no sustituye token A por B', () async {
    await f.login();
    await f.ready();
    final reached = Completer<void>(), release = Completer<void>();
    f.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          if (o.path == '/plantillas' &&
              o.headers['Authorization'] == 'Bearer fixture-access-1') {
            reached.complete();
            await release.future;
          }
          h.next(o);
        },
      ),
    );
    final old = f.binding.catalogo.load();
    await reached.future;
    await f.login(2);
    release.complete();
    await old;
    final request = f.adapter
        .matching('GET', '/plantillas')
        .lastWhere(
          (o) => o.headers['Authorization'] == 'Bearer fixture-access-1',
        );
    expect(request.headers['Authorization'], 'Bearer fixture-access-1');
    expect(f.sessions.current.value?.usuario.id, 2);
  });

  test(
    'respuesta de login A después de logout y login B no escribe token A',
    () async {
      final reached = Completer<void>(), release = Completer<void>();
      f.adapter.handler = (o) async {
        if (o.path == '/auth/login' &&
            (o.data as Map)['email'] == 'persona1@example.test') {
          reached.complete();
          await release.future;
        }
        return f.backend.respond(o);
      };
      final old = f.login();
      await reached.future;
      await f.binding.auth.logout();
      await f.login(2);
      release.complete();
      await old;
      expect(f.sessions.current.value?.usuario.id, 2);
      expect(f.secure.value, 'fixture-access-2');
      expect(f.secure.writes, 1);
    },
  );

  test(
    'dos auth controllers con escritura A en vuelo terminan almacenando B',
    () async {
      final reached = Completer<void>(), release = Completer<void>();
      f.secure.beforeWrite = () async {
        f.secure.beforeWrite = null;
        reached.complete();
        await release.future;
      };
      final old = f.login();
      await reached.future;
      final newer = AuthController(
        AuthRepository(f.binding.api),
        SecureTokenStorage(f.secure),
        f.sessions,
      );
      final loginB = newer.authenticate(
        'persona2@example.test',
        'Solo-Prueba-123',
      );
      expect(f.sessions.current.value, isNull);
      release.complete();
      await Future.wait([old, loginB]);
      expect(f.sessions.current.value?.usuario.id, 2);
      expect(f.secure.value, 'fixture-access-2');
      f.binding.auth.onClose();
      expect(f.sessions.current.value?.usuario.id, 2);
      newer.onClose();
    },
  );
}
