import 'dart:async';

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
    '21 objetos de API, cambio remoto visible y filtro favorito propio',
    () async {
      await f.login();
      await f.ready();
      expect(f.binding.catalogo.items, hasLength(21));
      expect(f.binding.catalogo.items.map((p) => p.id).toSet(), hasLength(21));
      await f.binding.catalogo.toggleFavorite(2);
      f.binding.catalogo.onlyFavorites.value = true;
      expect(f.binding.catalogo.visible.map((p) => p.id), [2]);
      f.backend.catalog = [
        {'id': 2, ...draftJson(titulo: 'Título cambiado en API')},
      ];
      await f.binding.catalogo.load();
      expect(
        f.binding.catalogo.visible.single.datos.titulo,
        'Título cambiado en API',
      );
      await f.login(2);
      await f.ready();
      expect(f.binding.catalogo.favoriteIds, isEmpty);
      await f.login();
      await f.ready();
      expect(f.binding.catalogo.favoriteIds, {2});
    },
  );

  test('catálogo viejo retenido no publica en B', () async {
    await f.login();
    await f.ready();
    final reached = Completer<void>(), release = Completer<void>();
    f.adapter.handler = (o) async {
      if (o.path == '/plantillas' && f.backend.user(o) == 1) {
        reached.complete();
        await release.future;
        return (
          status: 200,
          data: [
            {'id': 1, ...draftJson(titulo: 'Solo A')},
          ],
        );
      }
      return f.backend.respond(o);
    };
    final old = f.binding.catalogo.load();
    await reached.future;
    f.backend.catalog = [
      {'id': 2, ...draftJson(titulo: 'Solo B')},
    ];
    await f.login(2);
    await f.ready();
    release.complete();
    await old;
    expect(f.binding.catalogo.items.single.datos.titulo, 'Solo B');
    expect(f.binding.catalogo.loading.value, isFalse);
  });

  test(
    'vacío, malformado y error recuperan controles y permiten recargar',
    () async {
      await f.login();
      await f.ready();
      f.backend.catalog = [];
      await f.binding.catalogo.load();
      expect(f.binding.catalogo.items, isEmpty);
      f.backend.catalog = [
        {'id': 1, 'titulo': 'incompleto'},
      ];
      await f.binding.catalogo.load();
      expect(f.binding.catalogo.error.value, isNotNull);
      expect(f.binding.catalogo.loading.value, isFalse);
      f.backend.catalog = [
        {'id': 3, ...draftJson()},
      ];
      await f.binding.catalogo.load();
      expect(f.binding.catalogo.items.single.id, 3);
      expect(f.binding.catalogo.error.value, isNull);
    },
  );
}
