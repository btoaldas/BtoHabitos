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
        if (valid()) await driver.write(token);
      });

  Future<void> clear(bool Function() valid) => _queue.run(() async {
    if (valid()) await driver.delete();
  });
}
