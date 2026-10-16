import 'package:hive/hive.dart';

import '../services/async_queue.dart';

abstract interface class FavoritesBox {
  Set<int> get ids;
  Future<void> set(int id, bool selected);
  Future<void> flush();
  Future<void> close();
}

typedef OpenFavorites = Future<FavoritesBox> Function(String name);

class HiveFavoritesBox implements FavoritesBox {
  HiveFavoritesBox(this.box);
  final Box<int> box;
  @override
  Set<int> get ids => box.values.toSet();
  @override
  Future<void> set(int id, bool selected) async {
    if (selected) {
      await box.put(id, id);
    } else {
      await box.delete(id);
    }
  }

  @override
  Future<void> flush() => box.flush();
  @override
  Future<void> close() => box.close();
}

/// Un único dueño de los handles y de su orden, incluso entre repositorios.
class FavoritesCoordinator {
  static final shared = FavoritesCoordinator();
  final queue = AsyncQueue();
  Object? _desiredLease, _activeLease;
  FavoritesBox? _box;

  Future<void> _closeOriginal() async {
    final original = _box;
    _box = null;
    _activeLease = null;
    if (original != null) {
      try {
        await original.flush();
      } finally {
        await original.close();
      }
    }
  }
}

class FavoritosRepository {
  FavoritosRepository({OpenFavorites? open, FavoritesCoordinator? coordinator})
    : _open = open ?? _openHive,
      _hub = coordinator ?? FavoritesCoordinator.shared;

  static Future<FavoritesBox> _openHive(String name) async =>
      HiveFavoritesBox(await Hive.openBox<int>(name));
  final OpenFavorites _open;
  final FavoritesCoordinator _hub;
  Object? _lease;

  Future<Set<int>?> activate(int usuarioId, bool Function() valid) {
    final lease = Object();
    _lease = lease;
    _hub._desiredLease = lease;
    return _hub.queue.run(() async {
      bool current() => identical(_hub._desiredLease, lease) && valid();
      if (!current()) return null;
      await _hub._closeOriginal();
      if (!current()) return null;
      final original = await _open('favoritos_$usuarioId');
      _hub._box = original;
      _hub._activeLease = lease;
      if (!current()) {
        await _hub._closeOriginal();
        return null;
      }
      return original.ids;
    });
  }

  Future<Set<int>?> toggle(int id, bool Function() valid) {
    final lease = _lease;
    final original = _hub._box; // Capturada ANTES de la espera en la cola.
    return _hub.queue.run(() async {
      bool current() =>
          lease != null &&
          original != null &&
          valid() &&
          identical(_hub._desiredLease, lease) &&
          identical(_hub._activeLease, lease) &&
          identical(_hub._box, original);
      if (!current()) return null;
      await original!.set(id, !original.ids.contains(id));
      await original.flush();
      return current() ? original.ids : null;
    });
  }

  Future<void> deactivate() {
    final originalLease = _lease;
    _lease = null;
    if (identical(_hub._desiredLease, originalLease)) _hub._desiredLease = null;
    return _hub.queue.run(() async {
      if (originalLease != null &&
          identical(_hub._activeLease, originalLease)) {
        await _hub._closeOriginal();
      }
    });
  }
}
