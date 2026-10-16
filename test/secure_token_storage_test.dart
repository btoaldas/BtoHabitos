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
    'borrado y escritura obsoletos se comprueban al ejecutar la cola',
    () async {
      final driver = MemorySecureDriver()..value = 'fixture-access-1';
      final a = SecureTokenStorage(driver), b = SecureTokenStorage(driver);
      final reached = Completer<void>(), release = Completer<void>();
      driver.beforeRead = () async {
        reached.complete();
        await release.future;
      };
      final read = a.read();
      await reached.future;
      var validA = true;
      final obsoleteClear = a.clear(() => validA);
      final obsoleteWrite = a.write('fixture-obsolete', () => validA);
      validA = false;
      final newWrite = b.write('fixture-access-2', () => true);
      release.complete();
      await Future.wait<Object?>([
        read,
        obsoleteClear,
        obsoleteWrite,
        newWrite,
      ]);
      expect(driver.deletes, 0);
      expect(driver.writes, 1);
      expect(driver.value, 'fixture-access-2');
    },
  );

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
