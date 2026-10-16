import 'package:get/get.dart';

import '../services/session_authority.dart';

class OperationScope {
  const OperationScope(this.identity, this.revision);
  final SessionIdentity identity;
  final int revision;
}

abstract class SessionController extends GetxController {
  SessionController(this.sessions);
  final SessionAuthority sessions;
  late final Worker _worker;
  int _revision = 0;
  bool _closed = false;

  void bindSession() {
    _worker = ever(sessions.current, (_) {
      _revision++;
      reset();
      if (sessions.current.value != null) entered();
    });
    if (sessions.current.value != null) entered();
  }

  OperationScope? capture() {
    final identity = sessions.current.value;
    return identity == null || _closed
        ? null
        : OperationScope(identity, _revision);
  }

  bool accepts(OperationScope scope) =>
      !_closed &&
      scope.revision == _revision &&
      sessions.isCurrent(scope.identity);

  void reset();
  void entered() {}

  @override
  void onClose() {
    _closed = true;
    _revision++;
    _worker.dispose();
    reset();
    super.onClose();
  }
}
