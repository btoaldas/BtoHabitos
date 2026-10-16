import '../models/models.dart';
import '../services/api_client.dart';

class AuthRepository {
  AuthRepository(this.api);
  final ApiClient api;

  Future<Acceso> login(String email, String password) async => Acceso.fromJson(
    await api.request(
      'POST',
      '/auth/login',
      data: {'email': email, 'password': password},
    ),
  );

  Future<Usuario> register(String email, String password) async =>
      Usuario.fromJson(
        await api.request(
          'POST',
          '/auth/register',
          status: 201,
          data: {'email': email, 'password': password},
        ),
      );

  Future<Usuario> me(String originalToken) async => Usuario.fromJson(
    await api.request('GET', '/auth/me', restorationToken: originalToken),
  );
}
