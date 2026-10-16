import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'secure_token_storage.dart';
import 'session_authority.dart';

class AppFailure implements Exception {
  const AppFailure(this.message, {this.status});
  final String message;
  final int? status;
}

class StaleSession implements Exception {
  const StaleSession();
}

String failureMessage(Object error) => error is AppFailure
    ? error.message
    : error is FormatException
    ? 'El servidor devolvió una respuesta no válida. Inténtelo de nuevo.'
    : 'No se pudo completar la operación. Inténtelo de nuevo.';

class ApiClient {
  ApiClient({
    required this.sessions,
    required this.tokens,
    Dio? dio,
    this.deadline = const Duration(seconds: 30),
  }) : dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    if (deadline > const Duration(seconds: 30) || deadline <= Duration.zero) {
      throw ArgumentError('El tiempo máximo debe estar entre 0 y 30 segundos.');
    }
    this.dio.options
      ..connectTimeout = deadline
      ..sendTimeout = deadline
      ..receiveTimeout = deadline;
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:18310' : 'http://10.0.2.2:18310',
  );
  final Dio dio;
  final SessionAuthority sessions;
  final SecureTokenStorage tokens;
  final Duration deadline;

  Future<Object?> request(
    String method,
    String path, {
    Object? data,
    SessionIdentity? identity,
    int status = 200,
    String? restorationToken,
  }) async {
    if (identity != null && !sessions.isCurrent(identity)) {
      throw const StaleSession();
    }
    // Se captura aquí; ningún interceptor sustituye el token después de esperar.
    final originalToken = identity?.token ?? restorationToken;
    final cancel = CancelToken();
    try {
      final result = await dio
          .request<Object?>(
            path,
            data: data,
            cancelToken: cancel,
            options: Options(
              method: method,
              headers: {
                if (originalToken != null)
                  'Authorization': 'Bearer $originalToken',
                'Accept': 'application/json',
              },
            ),
          )
          .timeout(
            deadline,
            onTimeout: () {
              cancel.cancel();
              throw const AppFailure(
                'La solicitud tardó demasiado. Inténtelo de nuevo.',
              );
            },
          );
      if (result.statusCode != status) throw const FormatException();
      return result.data;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 && identity != null) {
        final ticket = sessions.expire(identity);
        if (ticket != null) {
          // La cola verifica otra vez el ticket, sin borrar una sesión nueva.
          unawaited(
            tokens
                .clear(() => sessions.accepts(ticket))
                .catchError((Object _) {}),
          );
        }
      }
      throw AppFailure(switch (code) {
        400 => 'No se pudo aceptar la solicitud. Revise los datos; la cuenta puede existir.',
        401 => 'La sesión no es válida. Inicie sesión de nuevo.',
        404 => 'El hábito ya no está disponible. Actualice la lista.',
        422 => 'Revise los campos e inténtelo de nuevo.',
        502 || 503 => 'El asistente no está disponible. Inténtelo más tarde.',
        504 => 'El asistente tardó demasiado. Inténtelo de nuevo.',
        int c when c >= 500 =>
          'El servidor no está disponible. Inténtelo de nuevo.',
        _ => switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout =>
            'La solicitud tardó demasiado. Inténtelo de nuevo.',
          DioExceptionType.connectionError =>
            'Sin conexión con el servidor. Revise su conexión y reintente.',
          _ => 'No se pudo conectar con el servidor. Inténtelo de nuevo.',
        },
      }, status: code);
    }
  }
}
