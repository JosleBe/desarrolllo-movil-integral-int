import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';

/// Canal para avisar que un endpoint privado respondió 401 (token vencido o
/// invalidado en el servidor). El controlador de sesión lo escucha.
class UnauthorizedEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;
  void emit() => _controller.add(null);
  Future<void> close() => _controller.close();
}

final unauthorizedEventsProvider = Provider<UnauthorizedEvents>((ref) {
  final events = UnauthorizedEvents();
  ref.onDispose(events.close);
  return events;
});

/// Cliente HTTP compartido. Adjunta el JWT a cada petición y cierra la
/// sesión local cuando el backend rechaza el token.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.readAccessToken();
        if (token != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final sentToken = error.requestOptions.headers.containsKey(
          'Authorization',
        );
        // Un 401 en /auth/login significa credenciales incorrectas, no sesión
        // vencida; solo cerramos sesión si la petición llevaba token.
        if (error.response?.statusCode == 401 && sentToken) {
          await tokenStorage.clear();
          ref.read(unauthorizedEventsProvider).emit();
        }
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // no imprimir contraseñas en consola
        responseBody: true,
        logPrint: (log) => debugPrint(log.toString()),
      ),
    );
  }

  return dio;
});
