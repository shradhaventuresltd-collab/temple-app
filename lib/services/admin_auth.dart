import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// True when the Firebase ID token custom claims include `admin: true`.
///
/// Custom claims are the admin definition for this app. Clients cannot set
/// them; grant with the Admin SDK (`scripts/grant_admin.js`).
bool hasAdminClaim(Map<String, dynamic>? claims) => claims?['admin'] == true;

/// Signed-in Firebase user plus whether they hold the admin claim.
@immutable
class AdminSession {
  const AdminSession({
    this.uid,
    this.email,
    this.isAdmin = false,
  });

  static const signedOut = AdminSession();

  final String? uid;
  final String? email;
  final bool isAdmin;

  bool get isSignedIn => uid != null;
}

/// Firebase Auth surface used by debug Seed/Admin write paths.
abstract class AdminAuth {
  Stream<AdminSession> get session;

  Future<bool> isCurrentUserAdmin();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Forces a token refresh so a newly granted `admin` claim is visible.
  Future<void> refreshClaims();

  static AdminAuth _instance = FirebaseAdminAuth();

  static AdminAuth get instance => _instance;

  @visibleForTesting
  static set instance(AdminAuth value) => _instance = value;

  @visibleForTesting
  static void resetInstance() => _instance = FirebaseAdminAuth();
}

class FirebaseAdminAuth implements AdminAuth {
  FirebaseAdminAuth({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance {
    _session = _auth.idTokenChanges().asyncMap(_sessionFor);
  }

  final FirebaseAuth _auth;
  late final Stream<AdminSession> _session;

  Future<AdminSession> _sessionFor(User? user) async {
    if (user == null) return AdminSession.signedOut;
    final token = await user.getIdTokenResult();
    return AdminSession(
      uid: user.uid,
      email: user.email,
      isAdmin: hasAdminClaim(token.claims),
    );
  }

  @override
  Stream<AdminSession> get session => _session;

  @override
  Future<bool> isCurrentUserAdmin() async {
    final session = await _sessionFor(_auth.currentUser);
    return session.isAdmin;
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> refreshClaims() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.getIdToken(true);
  }
}

/// Maps Firebase Auth errors to a short, user-visible message.
String adminSignInErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and retry.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Auth.';
      default:
        final message = error.message?.trim() ?? '';
        if (message.isEmpty || message.toLowerCase() == 'error') {
          return 'Sign-in failed (${error.code}). Check email/password '
              'and that Email/Password is enabled in Firebase Auth.';
        }
        return message;
    }
  }
  var text = error.toString().trim();
  if (text.startsWith('Exception:')) {
    text = text.substring('Exception:'.length).trim();
  }
  if (text.isEmpty || text.toLowerCase() == 'error') return 'Sign-in failed.';
  if (text.length > 180) text = '${text.substring(0, 177)}…';
  return text;
}
