import 'dart:async';

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

  Future<void> consult() async {
    f.binding.asistente.input.text = 'Proponga una lectura breve';
    await f.binding.asistente.consult();
  }

  test('cancelar produce cero POST de hábitos', () async {
    await f.login();
    await f.ready();
    await consult();
    expect(f.binding.asistente.reply.value?.propuesta?.titulo, 'Lectura breve');
    f.binding.asistente.discard();
    await f.binding.asistente.confirm();
    expect(f.adapter.matching('POST', '/habitos'), isEmpty);
    expect(f.backend.habits[1], isEmpty);
    expect(f.binding.asistente.reply.value, isNull);
  });

  test(
    'confirmar dos veces mientras POST espera crea exactamente un hábito',
    () async {
      await f.login();
      await f.ready();
      await consult();
      final reached = Completer<void>(), release = Completer<void>();
      f.adapter.handler = (o) async {
        if (o.path == '/habitos' && o.method == 'POST') {
          reached.complete();
          await release.future;
        }
        return f.backend.respond(o);
      };
      final first = f.binding.asistente.confirm();
      final second = f.binding.asistente.confirm();
      await reached.future;
      expect(f.adapter.matching('POST', '/habitos'), hasLength(1));
      expect(f.binding.asistente.confirming.value, isTrue);
      release.complete();
      await Future.wait([first, second]);
      await f.binding.asistente.confirm();
      expect(f.adapter.matching('POST', '/habitos'), hasLength(1));
      expect(f.backend.habits[1], hasLength(1));
      expect(f.binding.habitos.items.single.datos.titulo, 'Lectura breve');
      expect(f.binding.asistente.confirming.value, isFalse);
    },
  );

  test('consejo no presenta ni ejecuta creación', () async {
    await f.login();
    await f.ready();
    f.backend.assistant = {
      'tipo': 'consejo',
      'mensaje': 'Reserve un momento para planificar.',
    };
    await consult();
    await f.binding.asistente.confirm();
    expect(f.binding.asistente.reply.value?.propuesta, isNull);
    expect(f.binding.asistente.reply.value?.mensaje, contains('planificar'));
    expect(f.adapter.matching('POST', '/habitos'), isEmpty);
    expect((f.adapter.matching('POST', '/asistente').single.data as Map).keys, [
      'consulta',
    ]);
  });

  for (final leave in [false, true]) {
    test(
      'propuesta tardía descartada por ${leave ? 'salir de pestaña' : 'cambio de cuenta'}',
      () async {
        await f.login();
        await f.ready();
        final reached = Completer<void>(), release = Completer<void>();
        f.adapter.handler = (o) async {
          if (o.path == '/asistente') {
            reached.complete();
            await release.future;
          }
          return f.backend.respond(o);
        };
        final pending = consult();
        await reached.future;
        if (leave) {
          f.binding.asistente.discard();
        } else {
          await f.login(2);
          await f.ready();
        }
        release.complete();
        await pending;
        await f.binding.asistente.confirm();
        expect(f.binding.asistente.reply.value, isNull);
        expect(f.binding.asistente.loading.value, isFalse);
        expect(f.adapter.matching('POST', '/habitos'), isEmpty);
        expect(f.binding.asistente.input.text, isEmpty);
      },
    );
  }

  test('propuesta lista de A no se puede confirmar como B', () async {
    await f.login();
    await f.ready();
    await consult();
    await f.login(2);
    await f.ready();
    await f.binding.asistente.confirm();
    expect(f.adapter.matching('POST', '/habitos'), isEmpty);
    expect(f.binding.asistente.reply.value, isNull);
  });

  test('confirmación en vuelo de A no publica ni crea bajo B', () async {
    await f.login();
    await f.ready();
    await consult();
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/habitos' && o.method == 'POST') {
        reached.complete();
        await release.future;
      }
      return f.backend.respond(o);
    };
    final pending = f.binding.asistente.confirm();
    await reached.future;
    await f.login(2);
    await f.ready();
    release.complete();
    await pending;
    expect(f.backend.habits[1], hasLength(1));
    expect(f.backend.habits[2], isEmpty);
    expect(f.binding.asistente.feedback.value, isNull);
    expect(f.binding.habitos.items, isEmpty);
  });

  for (final status in [400, 401, 422, 500, 502, 503, 504]) {
    test(
      'asistente HTTP $status recupera consultar y confirmar sin altas',
      () async {
        await f.login();
        await f.ready();
        f.adapter.handler = (o) async => o.path == '/asistente'
            ? (
                status: status,
                data: {
                  'detail': [
                    {'msg': 'fallo sintético'},
                  ],
                },
              )
            : f.backend.respond(o);
        await consult();
        expect(f.binding.asistente.loading.value, isFalse);
        expect(f.binding.asistente.confirming.value, isFalse);
        expect(f.binding.asistente.reply.value, isNull);
        expect(f.adapter.matching('POST', '/habitos'), isEmpty);
        if (status == 401) {
          expect(f.sessions.current.value, isNull);
          await f.login();
          await f.ready();
        } else {
          expect(f.binding.asistente.error.value, isNotNull);
        }
        f.adapter.handler = null;
        await consult();
        expect(f.binding.asistente.reply.value?.propuesta, isNotNull);
      },
    );
  }

  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.receiveTimeout,
  ]) {
    test('fallo de transporte $type termina carga y deja reintentar', () async {
      await f.login();
      await f.ready();
      f.adapter.handler = (o) async {
        if (o.path == '/asistente') {
          throw DioException(requestOptions: o, type: type);
        }
        return f.backend.respond(o);
      };
      await consult();
      expect(f.binding.asistente.loading.value, isFalse);
      expect(f.binding.asistente.error.value, isNotNull);
      f.adapter.handler = null;
      await consult();
      expect(f.binding.asistente.reply.value?.propuesta, isNotNull);
    });
  }

  final malformed = <Object?>[
    'sin JSON',
    {'tipo': 'ejecutar', 'mensaje': 'No admitido'},
    {'tipo': 'consejo', 'mensaje': 'Idea', 'codigo': 'extra'},
    {
      'tipo': 'propuesta',
      'mensaje': 'Idea',
      'habito': {...draftJson(), 'user_id': 2},
    },
    {
      'tipo': 'propuesta',
      'mensaje': 'Idea',
      'habito': {...draftJson(), 'categoria': 'medicina'},
    },
    {'tipo': 'propuesta', 'mensaje': '', 'habito': draftJson()},
    {
      'tipo': 'propuesta',
      'mensaje': 'Idea',
      'habito': {...draftJson(), 'titulo': List.filled(101, 'a').join()},
    },
  ];
  for (var i = 0; i < malformed.length; i++) {
    test('salida malformada $i se rechaza por estructura y recupera', () async {
      await f.login();
      await f.ready();
      f.backend.assistant = malformed[i];
      await consult();
      await f.binding.asistente.confirm();
      expect(f.binding.asistente.error.value, isNotNull);
      expect(f.binding.asistente.reply.value, isNull);
      expect(f.binding.asistente.loading.value, isFalse);
      expect(f.adapter.matching('POST', '/habitos'), isEmpty);
      f.backend.assistant = proposalJson();
      await consult();
      expect(f.binding.asistente.reply.value?.propuesta, isNotNull);
    });
  }

  for (final status in [400, 401, 422, 500, 502, 503, 504]) {
    test(
      'error $status al confirmar permite recuperación y una alta en el doble',
      () async {
        await f.login();
        await f.ready();
        await consult();
        f.adapter.handler = (o) async =>
            o.path == '/habitos' && o.method == 'POST'
            ? (status: status, data: {'detail': 'fallo sintético'})
            : f.backend.respond(o);
        await f.binding.asistente.confirm();
        expect(f.binding.asistente.confirming.value, isFalse);
        expect(f.backend.habits[1], isEmpty);
        if (status == 401) {
          expect(f.sessions.current.value, isNull);
          expect(f.binding.asistente.reply.value, isNull);
          await f.login();
          await f.ready();
        } else {
          expect(f.binding.asistente.error.value, isNotNull);
        }
        f.adapter.handler = null;
        if (status == 401) await consult();
        await f.binding.asistente.confirm();
        expect(f.backend.habits[1], hasLength(1));
        expect(f.binding.asistente.reply.value, isNull);
      },
    );
  }

  for (final mode in ['red', 'timeout', 'malformado']) {
    test(
      'confirmación con $mode libera controles sin alta y permite reintentar',
      () async {
        await f.login();
        await f.ready();
        await consult();
        f.adapter.handler = (o) async {
          if (o.path != '/habitos' || o.method != 'POST') {
            return f.backend.respond(o);
          }
          if (mode == 'malformado') return (status: 201, data: {'id': 1});
          throw DioException(
            requestOptions: o,
            type: mode == 'red'
                ? DioExceptionType.connectionError
                : DioExceptionType.receiveTimeout,
          );
        };
        await f.binding.asistente.confirm();
        expect(f.binding.asistente.confirming.value, isFalse);
        expect(f.binding.asistente.error.value, isNotNull);
        expect(f.backend.habits[1], isEmpty);
        f.adapter.handler = null;
        await f.binding.asistente.confirm();
        expect(f.backend.habits[1], hasLength(1));
      },
    );
  }

  test(
    '401 de consulta antigua no cierra B ni muestra error en su asistente',
    () async {
      await f.login();
      await f.ready();
      final reached = Completer<void>(), release = Completer<void>();
      f.adapter.handler = (o) async {
        if (o.path == '/asistente') {
          reached.complete();
          await release.future;
          return (status: 401, data: {'detail': 'expirada'});
        }
        return f.backend.respond(o);
      };
      final pending = consult();
      await reached.future;
      await f.login(2);
      await f.ready();
      release.complete();
      await pending;
      expect(f.sessions.current.value?.usuario.id, 2);
      expect(f.binding.asistente.error.value, isNull);
      expect(f.secure.value, 'fixture-access-2');
    },
  );
}
