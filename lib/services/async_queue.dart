import 'dart:async';

/// Una operación fallida no rompe la cola de las siguientes operaciones.
class AsyncQueue {
  Future<void>? _tail;

  Future<T> run<T>(Future<T> Function() operation) {
    final previous = _tail;
    final finished = Completer<void>();
    _tail = finished.future;
    return _execute(previous, finished, operation);
  }

  Future<T> _execute<T>(
    Future<void>? previous,
    Completer<void> finished,
    Future<T> Function() operation,
  ) async {
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      // Antes de devolver el resultado, soltar la cola si ya está vacía.
      // Así no se retiene un Future de una zona anterior estando inactiva.
      if (identical(_tail, finished.future)) _tail = null;
      finished.complete();
    }
  }
}
