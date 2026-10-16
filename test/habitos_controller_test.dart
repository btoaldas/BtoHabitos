import 'dart:async';

import 'package:bto_habitos/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Fixture f;
  setUp(() {
    f = Fixture();
  });
  tearDown(() => f.close());

  test(
    'CRUD contra repositorio HTTP mide cuerpo, lista y persistencia del doble',
    () async {
      await f.login();
      await f.ready();
      final c = f.binding.habitos, identity = f.sessions.current.value!;
      expect(c.items, isEmpty);
      expect(
        await c.save(
          const HabitoDraft(titulo: 'Plan del día', categoria: 'organizacion'),
          identity: identity,
        ),
        isTrue,
      );
      final id = c.items.single.id;
      expect(f.backend.habits[1]![id]!['titulo'], 'Plan del día');
      expect(
        await c.save(
          const HabitoDraft(titulo: 'Plan semanal', frecuencia: 'semanal'),
          id: id,
          identity: identity,
        ),
        isTrue,
      );
      expect(c.items.single.datos.titulo, 'Plan semanal');
      expect(await c.toggle(c.items.single, identity), isTrue);
      expect(c.completed, 1);
      expect(f.backend.habits[1]![id]!['completado'], true);
      expect(await c.toggle(c.items.single, identity), isTrue);
      expect(c.completed, 0);
      await c.load();
      expect(c.items.single.datos.frecuencia, 'semanal');
      expect(await c.remove(c.items.single, identity), isTrue);
      expect(c.items, isEmpty);
      expect(f.backend.habits[1], isEmpty);
      final body = f.adapter.matching('POST', '/habitos').single.data as Map;
      expect(body.containsKey('user_id'), isFalse);
      expect(body.containsKey('id'), isFalse);
    },
  );

  test('alta desde plantilla conserva únicamente campos editables', () async {
    await f.login();
    await f.ready();
    final p = f.binding.catalogo.items.first;
    await f.binding.habitos.save(p.datos, identity: f.sessions.current.value!);
    final body = f.adapter.matching('POST', '/habitos').single.data as Map;
    expect(body['plantilla_id'], p.id);
    expect(body['titulo'], p.datos.titulo);
    expect(body.keys.toSet(), {
      'plantilla_id',
      'titulo',
      'descripcion',
      'categoria',
      'frecuencia',
      'tipo',
      'completado',
    });
  });

  test('POST tardío de A no publica hábito ni éxito en B', () async {
    await f.login();
    await f.ready();
    final identity = f.sessions.current.value!;
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/habitos' && o.method == 'POST') {
        reached.complete();
        await release.future;
      }
      return f.backend.respond(o);
    };
    final saving = f.binding.habitos.save(
      const HabitoDraft(titulo: 'Solo A'),
      identity: identity,
    );
    await reached.future;
    await f.login(2);
    await f.ready();
    release.complete();
    expect(await saving, isFalse);
    expect(f.sessions.current.value?.usuario.id, 2);
    expect(f.binding.habitos.items, isEmpty);
    expect(f.binding.habitos.feedback.value, isNull);
    expect(f.binding.habitos.mutating.value, isFalse);
    expect(f.backend.habits[1]!.values.single['titulo'], 'Solo A');
    expect(f.backend.habits[2], isEmpty);
  });

  test('listado/resumen tardío de A no altera avance de B', () async {
    await f.login();
    await f.ready();
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/habitos' && o.method == 'GET' && f.backend.user(o) == 1) {
        reached.complete();
        await release.future;
        return (
          status: 200,
          data: [habitJson(9, completed: true), habitJson(10, completed: true)],
        );
      }
      return f.backend.respond(o);
    };
    final old = f.binding.habitos.load();
    await reached.future;
    f.backend.habits[2] = {8: habitJson(8)};
    await f.login(2);
    await f.ready();
    release.complete();
    await old;
    expect(f.binding.habitos.items.map((h) => h.id), [8]);
    expect(f.binding.habitos.completed, 0);
  });

  test(
    'un refresh anterior a la mutación no revierte el cambio guardado',
    () async {
      await f.login();
      await f.ready();
      final reached = Completer<void>(), release = Completer<void>();
      f.adapter.handler = (o) async {
        if (o.path == '/habitos' && o.method == 'GET') {
          reached.complete();
          await release.future;
          return (status: 200, data: <Object?>[]);
        }
        return f.backend.respond(o);
      };
      final refresh = f.binding.habitos.load();
      await reached.future;
      await f.binding.habitos.save(
        const HabitoDraft(titulo: 'Nuevo'),
        identity: f.sessions.current.value!,
      );
      release.complete();
      await refresh;
      expect(f.binding.habitos.items.single.datos.titulo, 'Nuevo');
    },
  );

  for (final status in [400, 401, 422, 500]) {
    test('fallo CRUD $status mide cero altas y permite recuperar', () async {
      await f.login();
      await f.ready();
      f.adapter.handler = (o) async =>
          o.method == 'POST' && o.path == '/habitos'
          ? (
              status: status,
              data: {
                'detail': [
                  {'msg': 'sintético'},
                ],
              },
            )
          : f.backend.respond(o);
      expect(
        await f.binding.habitos.save(
          const HabitoDraft(titulo: 'Intento'),
          identity: f.sessions.current.value!,
        ),
        isFalse,
      );
      expect(f.binding.habitos.items, isEmpty);
      expect(f.binding.habitos.mutating.value, isFalse);
      expect(f.backend.habits[1], isEmpty);
      if (status == 401) {
        expect(f.sessions.current.value, isNull);
        await f.login();
        await f.ready();
      } else {
        expect(f.binding.habitos.mutationError.value, isNotNull);
      }
      f.adapter.handler = null;
      expect(
        await f.binding.habitos.save(
          const HabitoDraft(titulo: 'Reintento'),
          identity: f.sessions.current.value!,
        ),
        isTrue,
      );
      expect(f.backend.habits[1]!.values.single['titulo'], 'Reintento');
    });
  }

  for (final method in ['PATCH', 'DELETE']) {
    test('$method tardío conserva vista y datos de B', () async {
      f.backend.habits[1] = {9: habitJson(9)};
      f.backend.habits[2] = {12: habitJson(12, titulo: 'Rutina B')};
      await f.login();
      await f.ready();
      final oldHabit = f.binding.habitos.items.single,
          identity = f.sessions.current.value!;
      final reached = Completer<void>(), release = Completer<void>();
      f.adapter.handler = (o) async {
        if (o.path == '/habitos/9' && o.method == method) {
          reached.complete();
          await release.future;
        }
        return f.backend.respond(o);
      };
      final old = method == 'PATCH'
          ? f.binding.habitos.toggle(oldHabit, identity)
          : f.binding.habitos.remove(oldHabit, identity);
      await reached.future;
      await f.login(2);
      await f.ready();
      release.complete();
      expect(await old, isFalse);
      expect(f.binding.habitos.items.single.datos.titulo, 'Rutina B');
      expect(f.binding.habitos.completed, 0);
      expect(f.binding.habitos.feedback.value, isNull);
      expect(f.backend.habits[2]![12]!['completado'], false);
    });
  }
}
