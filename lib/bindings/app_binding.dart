import 'package:dio/dio.dart';

import '../controllers/asistente_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalogo_controller.dart';
import '../controllers/habitos_controller.dart';
import '../repositories/auth_repository.dart';
import '../repositories/favoritos_repository.dart';
import '../repositories/habitos_repository.dart';
import '../services/api_client.dart';
import '../services/asistente_service.dart';
import '../services/secure_token_storage.dart';
import '../services/session_authority.dart';

class AppBinding {
  AppBinding({
    Dio? dio,
    SecureStoreDriver? secure,
    SessionAuthority? sessions,
    FavoritosRepository? favorites,
  }) {
    this.sessions = sessions ?? SessionAuthority.shared;
    final tokens = SecureTokenStorage(secure ?? PluginSecureStore());
    api = ApiClient(sessions: this.sessions, tokens: tokens, dio: dio);
    auth = AuthController(AuthRepository(api), tokens, this.sessions);
    catalogo = CatalogoController(
      this.sessions,
      CatalogoRepository(api),
      favorites ?? FavoritosRepository(),
    );
    habitos = HabitosController(this.sessions, HabitosRepository(api));
    asistente = AsistenteController(
      this.sessions,
      AsistenteService(api),
      habitos,
    );
  }
  late final SessionAuthority sessions;
  late final ApiClient api;
  late final AuthController auth;
  late final CatalogoController catalogo;
  late final HabitosController habitos;
  late final AsistenteController asistente;

  void dispose() {
    asistente.onClose();
    habitos.onClose();
    catalogo.onClose();
    auth.onClose();
    api.dio.close();
  }
}
