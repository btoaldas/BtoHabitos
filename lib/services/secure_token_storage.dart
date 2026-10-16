import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'async_queue.dart';

abstract interface class SecureStoreDriver {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class PluginSecureStore implements SecureStoreDriver {
  PluginSecureStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
          );
  final FlutterSecureStorage _storage;
  static const _key = 'bto_habitos_session';

  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class SecureTokenStorage {
  SecureTokenStorage(this.driver);
  final SecureStoreDriver driver;
  static final _queue = AsyncQueue();

  Future<String?> read() => _queue.run(driver.read);

  Future<void> write(String token, bool Function() valid) =>
      _queue.run(() async {
        if (!valid()) return;
        try {
          await driver.write(token);
        } finally {
          // La escritura nativa no se puede cancelar. Si perdió su sesión,
          // retirarla antes de soltar la cola: ninguna lectura ni credencial
          // posterior puede adelantarse a esta compensación.
          if (!valid()) await driver.delete();
        }
      });

  Future<void> clear(bool Function() valid) {
    // Se acepta la revocación ahora. Un restore posterior no puede anularla;
    // una escritura nueva queda detrás del borrado en la misma cola FIFO.
    // Una petición que ya llega obsoleta (p. ej. un 401 de A tras login B)
    // sigue sin tener autoridad para retirar la credencial actual.
    if (!valid()) return Future<void>.value();
    return _queue.run(driver.delete);
  }
}
