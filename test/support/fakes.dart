import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bto_habitos/bindings/app_binding.dart';
import 'package:bto_habitos/repositories/favoritos_repository.dart';
import 'package:bto_habitos/services/secure_token_storage.dart';
import 'package:bto_habitos/services/session_authority.dart';
import 'package:dio/dio.dart';

/// Dobles explícitos: solo datos sintéticos; no hay API ni llavero externos.
class MemorySecureDriver implements SecureStoreDriver {
  String? value;
  Future<void> Function()? beforeRead, beforeWrite, beforeDelete;
  int reads = 0, writes = 0, deletes = 0;

  @override
  Future<String?> read() async {
    reads++;
    final captured = value;
    await beforeRead?.call();
    return captured;
  }

  @override
  Future<void> write(String token) async {
    writes++;
    await beforeWrite?.call();
    value = token;
  }

  @override
  Future<void> delete() async {
    deletes++;
    await beforeDelete?.call();
    value = null;
  }
}

class MemoryFavoritesBox implements FavoritesBox {
  MemoryFavoritesBox(this.data);
  final Set<int> data;
  bool closed = false;
  Future<void> Function()? beforeFlush, beforeClose, beforeSet;
  @override
  Set<int> get ids {
    if (closed) throw StateError('Caja cerrada');
    return data.toSet();
  }

  @override
  Future<void> set(int id, bool selected) async {
    if (closed) throw StateError('Caja cerrada');
    await beforeSet?.call();
    if (selected) {
      data.add(id);
    } else {
      data.remove(id);
    }
  }

  @override
  Future<void> flush() async {
    await beforeFlush?.call();
  }

  @override
  Future<void> close() async {
    await beforeClose?.call();
    closed = true;
  }
}

class MemoryFavorites {
  final data = <String, Set<int>>{};
  final opened = <String>[];
  final boxes = <MemoryFavoritesBox>[];
  Future<FavoritesBox> open(String name) async {
    opened.add(name);
    final box = MemoryFavoritesBox(data.putIfAbsent(name, () => <int>{}));
    boxes.add(box);
    return box;
  }
}

typedef HttpReply = ({int status, Object? data});

class FixtureAdapter implements HttpClientAdapter {
  FixtureAdapter(this.backend);
  final FixtureBackend backend;
  final requests = <RequestOptions>[];
  Future<HttpReply> Function(RequestOptions)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = await (handler?.call(options) ?? backend.respond(options));
    return ResponseBody.fromString(
      reply.status == 204 ? '' : jsonEncode(reply.data),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  List<RequestOptions> matching(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path).toList();
}

Map<String, dynamic> draftJson({String titulo = 'Lectura breve'}) => {
  'titulo': titulo,
  'descripcion': 'Diez minutos para aprender.',
  'categoria': 'aprendizaje',
  'frecuencia': 'diaria',
  'tipo': 'habito',
};

Map<String, dynamic> habitJson(
  int id, {
  bool completed = false,
  String titulo = 'Lectura breve',
}) => {
  'id': id,
  ...draftJson(titulo: titulo),
  'completado': completed,
  'created_at': '2026-10-15T12:00:00Z',
  'updated_at': '2026-10-15T12:00:00Z',
};

Map<String, dynamic> proposalJson() => {
  'tipo': 'propuesta',
  'mensaje': 'Empiece con un paso pequeño.',
  'habito': draftJson(),
};

class FixtureBackend {
  Object? catalog = List.generate(
    21,
    (i) => {'id': i + 1, ...draftJson(titulo: 'Idea ${i + 1}')},
  );
  Object? assistant = proposalJson();
  final habits = <int, Map<int, Map<String, dynamic>>>{};
  int _nextId = 1;

  int user(RequestOptions options) =>
      options.headers['Authorization'] == 'Bearer fixture-access-2' ? 2 : 1;

  Future<HttpReply> respond(RequestOptions options) async {
    final data = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : <String, dynamic>{};
    if (options.path == '/auth/register') {
      return (status: 201, data: {'id': 3, 'email': data['email']});
    }
    if (options.path == '/auth/login') {
      final id = data['email'] == 'persona2@example.test' ? 2 : 1;
      return (
        status: 200,
        data: {
          'access_token': 'fixture-access-$id',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {'id': id, 'email': data['email']},
        },
      );
    }
    final id = user(options);
    if (options.path == '/auth/me') {
      return (
        status: 200,
        data: {'id': id, 'email': 'persona$id@example.test'},
      );
    }
    if (options.path == '/plantillas') return (status: 200, data: catalog);
    if (options.path == '/asistente') return (status: 200, data: assistant);
    final own = habits.putIfAbsent(id, () => {});
    if (options.path == '/habitos' && options.method == 'GET') {
      return (status: 200, data: own.values.toList());
    }
    if (options.path == '/habitos' && options.method == 'POST') {
      final habit = {
        'id': _nextId++,
        ...data,
        'completado': data['completado'] ?? false,
      };
      own[habit['id']! as int] = habit;
      return (status: 201, data: habit);
    }
    final habitId = int.tryParse(options.path.split('/').last);
    if (habitId != null && own.containsKey(habitId)) {
      if (options.method == 'PATCH') {
        final updated = {...own[habitId]!, ...data};
        own[habitId] = updated;
        return (status: 200, data: updated);
      }
      if (options.method == 'DELETE') {
        own.remove(habitId);
        return (status: 204, data: null);
      }
    }
    return (status: 404, data: {'detail': 'No disponible'});
  }
}

class Fixture {
  Fixture() {
    adapter = FixtureAdapter(backend);
    dio = Dio(BaseOptions(baseUrl: 'http://fixture.invalid'))
      ..httpClientAdapter = adapter;
    favorites = FavoritosRepository(
      open: favoriteMemory.open,
      coordinator: favoriteHub,
    );
    binding = AppBinding(
      dio: dio,
      secure: secure,
      sessions: sessions,
      favorites: favorites,
    );
  }
  final secure = MemorySecureDriver();
  final sessions = SessionAuthority();
  final backend = FixtureBackend();
  final favoriteMemory = MemoryFavorites();
  final favoriteHub = FavoritesCoordinator();
  late final FixtureAdapter adapter;
  late final Dio dio;
  late final FavoritosRepository favorites;
  late final AppBinding binding;

  Future<void> login([int id = 1]) =>
      binding.auth.authenticate('persona$id@example.test', 'Solo-Prueba-123');
  Future<void> ready() async {
    await binding.catalogo.load();
    await binding.habitos.load();
    await favoriteHub.queue.run(() async {});
  }

  Future<void> close() async {
    binding.dispose();
    await favoriteHub.queue.run(() async {});
  }
}
