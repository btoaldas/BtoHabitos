import 'dart:async';

import 'package:bto_habitos/models/models.dart';
import 'package:bto_habitos/services/api_client.dart';
import 'package:bto_habitos/services/secure_token_storage.dart';
import 'package:bto_habitos/services/session_authority.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('la petición completa vence realmente a los 30s con reloj virtual', () {
    fakeAsync((clock) {
      final sessions = SessionAuthority();
      final ticket = sessions.begin(Object());
      sessions.publish(
        ticket,
        'fixture-access-1',
        const Usuario(1, 'persona1@example.test'),
      );
      final identity = sessions.current.value!;
      final release = Completer<void>();
      final adapter = FixtureAdapter(FixtureBackend())
        ..handler = (o) async {
          await release.future;
          return (
            status: 200,
            data: {'tipo': 'consejo', 'mensaje': 'Respuesta atrasada'},
          );
        };
      final dio = Dio(BaseOptions(baseUrl: 'http://fixture.invalid'))
        ..httpClientAdapter = adapter;
      final api = ApiClient(
        sessions: sessions,
        tokens: SecureTokenStorage(MemorySecureDriver()),
        dio: dio,
      );
      Object? result;
      api
          .request(
            'POST',
            '/asistente',
            identity: identity,
            data: {'consulta': 'Una idea'},
          )
          .then<void>(
            (value) {
              result = value;
            },
            onError: (Object error) {
              result = error;
            },
          );
      clock.flushMicrotasks();
      clock.elapse(Duration.zero);
      clock.flushMicrotasks();
      expect(adapter.requests, hasLength(1));
      clock.elapse(const Duration(seconds: 29));
      clock.flushMicrotasks();
      expect(result, isNull);
      clock.elapse(const Duration(seconds: 1));
      clock.flushMicrotasks();
      expect(result, isA<AppFailure>());
      expect((result! as AppFailure).message, contains('tardó demasiado'));
      expect(sessions.isCurrent(identity), isTrue);
      release.complete();
      clock.flushMicrotasks();
      dio.close();
    });
  });

  test('no permite configurar esperas superiores al contrato', () {
    expect(
      () => ApiClient(
        sessions: SessionAuthority(),
        tokens: SecureTokenStorage(MemorySecureDriver()),
        deadline: const Duration(seconds: 31),
      ),
      throwsArgumentError,
    );
  });
}
