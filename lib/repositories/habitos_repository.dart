import '../models/models.dart';
import '../services/api_client.dart';
import '../services/session_authority.dart';

List<T> _list<T>(Object? json, T Function(Object?) parse, int Function(T) id) {
  if (json is! List) throw const FormatException();
  final items = json.map(parse).toList(growable: false);
  if (items.map(id).toSet().length != items.length) {
    throw const FormatException();
  }
  return items;
}

class CatalogoRepository {
  CatalogoRepository(this.api);
  final ApiClient api;
  Future<List<Plantilla>> list(SessionIdentity identity) async => _list(
    await api.request('GET', '/plantillas', identity: identity),
    Plantilla.fromJson,
    (p) => p.id,
  );
}

class HabitosRepository {
  HabitosRepository(this.api);
  final ApiClient api;

  Future<List<Habito>> list(SessionIdentity identity) async => _list(
    await api.request('GET', '/habitos', identity: identity),
    Habito.fromJson,
    (h) => h.id,
  );

  Future<Habito> save(
    SessionIdentity identity,
    HabitoDraft draft, {
    int? id,
  }) async => Habito.fromJson(
    await api.request(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/habitos' : '/habitos/$id',
      identity: identity,
      status: id == null ? 201 : 200,
      data: draft.toJson(),
    ),
  );

  Future<Habito> complete(SessionIdentity identity, Habito habito) async =>
      Habito.fromJson(
        await api.request(
          'PATCH',
          '/habitos/${habito.id}',
          identity: identity,
          data: {'completado': !habito.datos.completado},
        ),
      );

  Future<void> remove(SessionIdentity identity, int id) async {
    await api.request(
      'DELETE',
      '/habitos/$id',
      identity: identity,
      status: 204,
    );
  }
}
