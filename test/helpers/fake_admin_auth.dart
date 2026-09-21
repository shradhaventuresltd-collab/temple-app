import 'dart:async';

import 'package:temple_app/services/admin_auth.dart';

class FakeAdminAuth implements AdminAuth {
  FakeAdminAuth({AdminSession initial = AdminSession.signedOut})
      : _session = initial {
    _controller = StreamController<AdminSession>.broadcast();
    session = Stream<AdminSession>.multi((listener) {
      listener.add(_session);
      final sub = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = sub.cancel;
    });
  }

  AdminSession _session;
  late final StreamController<AdminSession> _controller;

  @override
  late final Stream<AdminSession> session;

  Object? signInError;
  int signInCalls = 0;
  int signOutCalls = 0;
  int refreshCalls = 0;
  String? lastEmail;
  String? lastPassword;

  AdminSession get current => _session;

  void emit(AdminSession session) {
    _session = session;
    _controller.add(session);
  }

  @override
  Future<bool> isCurrentUserAdmin() async => _session.isAdmin;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    if (signInError != null) {
      throw signInError!;
    }
    emit(AdminSession(uid: 'uid-1', email: email, isAdmin: false));
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(AdminSession.signedOut);
  }

  @override
  Future<void> refreshClaims() async {
    refreshCalls++;
  }
}
