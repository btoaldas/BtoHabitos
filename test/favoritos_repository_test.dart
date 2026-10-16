import 'dart:async';
import 'dart:io';

import 'package:bto_habitos/repositories/favoritos_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/fakes.dart';

void main() {
  test('Hive real persiste A→B→A y solo conserva identificadores', () async {
    final parent = Directory('.tmp/flutter-l01-l02/fixtures')
      ..createSync(recursive: true);
    final temp = parent.createTempSync('hive-real-');
    Hive.init(temp.path);
    final hub = FavoritesCoordinator();
    final a = FavoritosRepository(coordinator: hub),
        b = FavoritosRepository(coordinator: hub);
    try {
      expect(await a.activate(1, () => true), isEmpty);
      expect(await a.toggle(7, () => true), {7});
      expect(await a.toggle(12, () => true), {7, 12});
      await a.deactivate();
      expect(await b.activate(2, () => true), isEmpty);
      expect(await b.toggle(3, () => true), {3});
      await b.deactivate();
      expect(await a.activate(1, () => true), {7, 12});
      expect(await a.toggle(7, () => true), {12});
      await a.deactivate();
      final raw = await Hive.openBox<int>('favoritos_1');
      expect(raw.keys.toSet(), {12});
      expect(raw.values.toList(), [12]);
      await raw.close();
      expect(await b.activate(2, () => true), {3});
    } finally {
      await a.deactivate();
      await b.deactivate();
      await Hive.close();
      // Exclusivamente el fixture nuevo creado por esta prueba.
      await temp.delete(recursive: true);
    }
  });

  test(
    'B no abre mientras A espera flush y close; cierre antiguo no cierra B',
    () async {
      final memory = MemoryFavorites(), hub = FavoritesCoordinator();
      final a = FavoritosRepository(open: memory.open, coordinator: hub);
      final b = FavoritosRepository(open: memory.open, coordinator: hub);
      await a.activate(1, () => true);
      await a.toggle(8, () => true);
      final boxA = memory.boxes.single;
      final flushing = Completer<void>(), flushRelease = Completer<void>();
      final closing = Completer<void>(), closeRelease = Completer<void>();
      boxA.beforeFlush = () async {
        flushing.complete();
        await flushRelease.future;
      };
      boxA.beforeClose = () async {
        closing.complete();
        await closeRelease.future;
      };
      final exitA = a.deactivate();
      await flushing.future;
      final enterB = b.activate(2, () => true);
      expect(memory.opened, ['favoritos_1']);
      flushRelease.complete();
      await closing.future;
      expect(memory.opened, ['favoritos_1']);
      closeRelease.complete();
      await exitA;
      expect(await enterB, isEmpty);
      expect(boxA.closed, isTrue);
      expect(memory.opened, ['favoritos_1', 'favoritos_2']);
      await a.deactivate();
      expect(memory.boxes.last.closed, isFalse);
      expect(await b.toggle(4, () => true), {4});
      await b.deactivate();
      expect(memory.data['favoritos_1'], {8});
    },
  );

  test('una apertura A retenida se cierra antes de abrir B', () async {
    final memory = MemoryFavorites(), hub = FavoritesCoordinator();
    final reached = Completer<void>(), release = Completer<void>();
    Future<FavoritesBox> open(String name) async {
      if (name == 'favoritos_1') {
        reached.complete();
        await release.future;
      }
      return memory.open(name);
    }

    final a = FavoritosRepository(open: open, coordinator: hub);
    final b = FavoritosRepository(open: open, coordinator: hub);
    final openingA = a.activate(1, () => true);
    await reached.future;
    final openingB = b.activate(2, () => true);
    release.complete();
    expect(await openingA, isNull);
    expect(await openingB, isEmpty);
    expect(memory.boxes.first.closed, isTrue);
    expect(memory.boxes.last.closed, isFalse);
    await a.deactivate();
    expect(await b.toggle(5, () => true), {5});
    await b.deactivate();
  });

  test('escritura A captura su caja; nunca escribe en B', () async {
    final memory = MemoryFavorites(), hub = FavoritesCoordinator();
    final a = FavoritosRepository(open: memory.open, coordinator: hub);
    final b = FavoritosRepository(open: memory.open, coordinator: hub);
    await a.activate(1, () => true);
    final reached = Completer<void>(), release = Completer<void>();
    memory.boxes.first.beforeSet = () async {
      reached.complete();
      await release.future;
    };
    final writing = a.toggle(9, () => true);
    await reached.future;
    final openingB = b.activate(2, () => true);
    expect(memory.opened, ['favoritos_1']);
    release.complete();
    expect(await writing, isNull);
    expect(await openingB, isEmpty);
    expect(memory.data['favoritos_1'], {9});
    expect(memory.data['favoritos_2'], isEmpty);
    await a.deactivate();
    await b.deactivate();
  });
}
