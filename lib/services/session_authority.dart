import 'package:get/get.dart';

import '../models/models.dart';

class SessionTicket {
  const SessionTicket(this.generation, this.owner);
  final int generation;
  final Object owner;
}

class SessionIdentity {
  const SessionIdentity(this.generation, this.token, this.usuario);
  final int generation;
  final String token;
  final Usuario usuario;
}

/// Compartida en el proceso: también protege al sustituir un AuthController.
class SessionAuthority {
  static final shared = SessionAuthority();
  final current = Rxn<SessionIdentity>();
  int _generation = 0;
  Object? _owner;
  String? notice;

  SessionTicket begin(Object owner, {String? message}) {
    _generation++;
    _owner = owner;
    notice = message;
    current.value = null; // Invalida antes de cualquier espera.
    return SessionTicket(_generation, owner);
  }

  bool owns(Object owner) => identical(owner, _owner);
  bool accepts(SessionTicket ticket) =>
      ticket.generation == _generation && identical(ticket.owner, _owner);
  bool isCurrent(SessionIdentity identity) =>
      identity.generation == _generation && identical(current.value, identity);

  bool publish(SessionTicket ticket, String token, Usuario usuario) {
    if (!accepts(ticket)) return false;
    current.value = SessionIdentity(_generation, token, usuario);
    return true;
  }

  SessionTicket? expire(SessionIdentity identity) {
    if (!isCurrent(identity)) return null;
    return begin(_owner!, message: 'Su sesión expiró. Inicie sesión de nuevo.');
  }
}
