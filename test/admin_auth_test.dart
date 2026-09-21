import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  test('hasAdminClaim is true only for admin: true', () {
    expect(hasAdminClaim(null), isFalse);
    expect(hasAdminClaim({}), isFalse);
    expect(hasAdminClaim({'admin': false}), isFalse);
    expect(hasAdminClaim({'admin': 'true'}), isFalse);
    expect(hasAdminClaim({'role': 'admin'}), isFalse);
    expect(hasAdminClaim({'admin': true}), isTrue);
  });

  test('adminSignInErrorMessage maps FirebaseAuthException codes', () {
    expect(
      adminSignInErrorMessage(
        FirebaseAuthException(code: 'invalid-credential'),
      ),
      'Email or password is incorrect.',
    );
    expect(
      adminSignInErrorMessage(
        FirebaseAuthException(code: 'operation-not-allowed'),
      ),
      'Email/password sign-in is not enabled in Firebase Auth.',
    );
    expect(
      adminSignInErrorMessage(Exception('permission-denied')),
      'permission-denied',
    );
    expect(adminSignInErrorMessage(Exception('')), 'Sign-in failed.');
  });

  test('seedTempleData throws when isAdmin is false', () async {
    expect(
      () => seedTempleData(isAdmin: () async => false),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('signed-in admin'),
        ),
      ),
    );
  });
}
