import '../models/models.dart';
import 'api_client.dart';
import 'session_authority.dart';

class AsistenteService {
  AsistenteService(this.api);
  final ApiClient api;

  Future<RespuestaAsistente> consult(
    SessionIdentity identity,
    String consulta,
  ) async {
    if (consulta.trim().isEmpty || consulta.length > 1000) {
      throw const AppFailure('Escriba una consulta de 1 a 1000 caracteres.');
    }
    return RespuestaAsistente.fromJson(
      await api.request(
        'POST',
        '/asistente',
        identity: identity,
        data: {'consulta': consulta},
      ),
    );
  }
}
