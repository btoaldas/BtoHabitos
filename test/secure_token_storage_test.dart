import 'dart:async';

import 'package:bto_habitos/services/secure_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test(
    'dos instancias serializan lectura/escritura y no adelantan B',
    () async {
      final driver = MemorySecureDriver();
      final a = SecureTokenStorage(driver), b = SecureTokenStorage(driver);
      final reached = Completer<void>(), release = Completer<void>();
      driver.beforeWrite = () async {
        driver.beforeWrite = null;
        reached.complete();
        await release.future;
      };
      final writeA = a.write('fixture-access-1', () => true);
      addTearDown(() async {
        if (!release.isCompleted) release.complete();
        await writeA;
        await a.read();
      });
      await reached.future;
      final readB = b.read();
      final writeB = b.write('fixture-access-2', () => true);
      expect(driver.reads, 0);
      expect(driver.writes, 1);
      release.complete();
      await writeA;
      expect(await readB, 'fixture-access-1');
      await writeB;
      expect(driver.value, 'fixture-access-2');
    },
  );

  test(
    'borrado aceptado precede a B aunque su ticket cambie en la cola',
    () async {
      final driver = MemorySecureDriver()..value = 'fixture-access-1';
      final a = SecureTokenStorage(driver), b = SecureTokenStorage(driver);
      final reached = Completer<void>(), release = Completer<void>();
      driver.beforeRead = () async {
        driver.beforeRead = null;
        reached.complete();
        await release.future;
      };
      final read = a.read();
      addTearDown(() async {
        if (!release.isCompleted) release.complete();
        await read;
        await a.read();
      });
      await reached.future;
      var validA = true;
      final acceptedClear = a.clear(() => validA);
      final obsoleteWrite = a.write('fixture-obsolete', () => validA);
      validA = false;
      final newWrite = b.write('fixture-access-2', () => true);
      release.complete();
      await Future.wait<Object?>([
        read,
        acceptedClear,
        obsoleteWrite,
        newWrite,
      ]);
      // clear se aceptó con A válido antes de encolar B. El borrado debe
      // ejecutarse incluso si A pierde su ticket; nunca se ejecuta tras B.
      expect(driver.deletes, 1);
      expect(driver.writes, 1);
      expect(driver.value, 'fixture-access-2');
    },
  );

  test('un borrado ya obsoleto al solicitarse conserva B', () async {
    final driver = MemorySecureDriver()..value = 'fixture-access-2';
    final storage = SecureTokenStorage(driver);
    await storage.clear(() => false);
    expect(driver.deletes, 0);
    expect(await storage.read(), 'fixture-access-2');
  });

  test('write nativo obsoleto se retira antes de una lectura B', () async {
    final driver = MemorySecureDriver();
    final a = SecureTokenStorage(driver), b = SecureTokenStorage(driver);
    final reached = Completer<void>(), release = Completer<void>();
    var validA = true;
    driver.beforeWrite = () async {
      driver.beforeWrite = null;
      reached.complete();
      await release.future;
    };
    final writing = a.write('fixture-access-1', () => validA);
    addTearDown(() async {
      if (!release.isCompleted) release.complete();
      await writing;
      await b.read();
    });
    await reached.future;
    final reading = b.read();
    validA = false;
    release.complete();
    await writing;
    expect(await reading, isNull);
    expect(driver.value, isNull);
    expect(driver.writes, 1);
    expect(driver.deletes, 1);
  });

  test('compensación de A retiene la cola y no borra escritura B', () async {
    final driver = MemorySecureDriver();
    final a = SecureTokenStorage(driver), b = SecureTokenStorage(driver);
    final writeReached = Completer<void>(), writeRelease = Completer<void>();
    final deleteReached = Completer<void>(), deleteRelease = Completer<void>();
    var validA = true;
    driver.beforeWrite = () async {
      driver.beforeWrite = null;
      writeReached.complete();
      await writeRelease.future;
    };
    driver.beforeDelete = () async {
      driver.beforeDelete = null;
      deleteReached.complete();
      await deleteRelease.future;
    };
    final writingA = a.write('fixture-access-1', () => validA);
    Future<void>? writingB;
    addTearDown(() async {
      if (!writeRelease.isCompleted) writeRelease.complete();
      if (!deleteRelease.isCompleted) deleteRelease.complete();
      await writingA;
      if (writingB != null) await writingB;
      await b.read();
    });
    await writeReached.future;
    writingB = b.write('fixture-access-2', () => true);
    validA = false;
    writeRelease.complete();
    final compensating = await Future.any([
      deleteReached.future.then((_) => true),
      writingA.then((_) => false),
    ]);
    expect(compensating, isTrue);
    expect(driver.writes, 1);
    expect(driver.value, 'fixture-access-1');
    deleteRelease.complete();
    await Future.wait([writingA, writingB]);
    expect(driver.value, 'fixture-access-2');
    expect(driver.writes, 2);
    expect(driver.deletes, 1);
  });

  test('una operación fallida no bloquea las siguientes', () async {
    final driver = MemorySecureDriver();
    final a = SecureTokenStorage(driver), b = SecureTokenStorage(driver);
    driver.beforeWrite = () async {
      throw StateError('fallo controlado');
    };
    await expectLater(
      a.write('fixture-access-1', () => true),
      throwsStateError,
    );
    driver.beforeWrite = null;
    await b.write('fixture-access-2', () => true);
    expect(await b.read(), 'fixture-access-2');
  });
}
