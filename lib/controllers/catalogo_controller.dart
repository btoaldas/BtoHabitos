import 'dart:async';

import 'package:get/get.dart';

import '../models/models.dart';
import '../repositories/favoritos_repository.dart';
import '../repositories/habitos_repository.dart';
import '../services/api_client.dart';
import 'session_controller.dart';

class CatalogoController extends SessionController {
  CatalogoController(super.sessions, this.repository, this.favorites) {
    bindSession();
  }
  final CatalogoRepository repository;
  final FavoritosRepository favorites;
  final items = <Plantilla>[].obs;
  final favoriteIds = <int>{}.obs;
  final loading = false.obs,
      favoritesLoading = false.obs,
      onlyFavorites = false.obs;
  final error = RxnString(), favoritesError = RxnString();
  int _load = 0;

  List<Plantilla> get visible => onlyFavorites.value
      ? items.where((p) => favoriteIds.contains(p.id)).toList()
      : items.toList();

  @override
  void entered() {
    unawaited(load());
    unawaited(loadFavorites());
  }

  @override
  void reset() {
    _load++;
    items.clear();
    favoriteIds.clear();
    onlyFavorites.value = false;
    loading.value = favoritesLoading.value = false;
    error.value = favoritesError.value = null;
    unawaited(favorites.deactivate().catchError((Object _) {}));
  }

  Future<void> load() async {
    final scope = capture();
    if (scope == null) return;
    final serial = ++_load;
    loading.value = true;
    error.value = null;
    try {
      final result = await repository.list(scope.identity);
      if (accepts(scope) && serial == _load) items.assignAll(result);
    } catch (e) {
      if (accepts(scope) && serial == _load) error.value = failureMessage(e);
    } finally {
      if (accepts(scope) && serial == _load) loading.value = false;
    }
  }

  Future<void> loadFavorites() async {
    final scope = capture();
    if (scope == null || favoritesLoading.value) return;
    favoritesLoading.value = true;
    favoritesError.value = null;
    try {
      final ids = await favorites.activate(
        scope.identity.usuario.id,
        () => accepts(scope),
      );
      if (accepts(scope) && ids != null) favoriteIds.assignAll(ids);
    } catch (_) {
      if (accepts(scope)) {
        favoritesError.value = 'No se pudieron abrir sus favoritos. Reintente.';
      }
    } finally {
      if (accepts(scope)) favoritesLoading.value = false;
    }
  }

  Future<void> toggleFavorite(int id) async {
    final scope = capture();
    if (scope == null || favoritesLoading.value) return;
    favoritesLoading.value = true;
    favoritesError.value = null;
    try {
      final ids = await favorites.toggle(id, () => accepts(scope));
      if (ids == null) {
        if (accepts(scope)) {
          favoritesError.value = 'Abra sus favoritos de nuevo para continuar.';
        }
      } else if (accepts(scope)) {
        favoriteIds.assignAll(ids);
      }
    } catch (_) {
      if (accepts(scope)) {
        favoritesError.value = 'No se pudo guardar el favorito. Reintente.';
      }
    } finally {
      if (accepts(scope)) favoritesLoading.value = false;
    }
  }
}
