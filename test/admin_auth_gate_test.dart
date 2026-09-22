import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/screens/admin_screen.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/seed_service.dart';
import 'package:temple_app/widgets/debug_home_admin_actions.dart';

import 'helpers/fake_admin_auth.dart';

void main() {
  testWidgets(
      'AdminScreen hides sign-in and CMS when debug flag is false (release gate)',
      (tester) async {
    final auth = FakeAdminAuth();

    await tester.pumpWidget(
      MaterialApp(
        home: AdminScreen(adminAuth: auth, isDebug: false),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('admin-unavailable-message')), findsOneWidget);
    expect(
      find.text('Admin CMS is available in debug builds only.'),
      findsOneWidget,
    );
    expect(find.text('Admin sign-in required'), findsNothing);
    expect(find.byKey(const Key('admin-sign-in-button')), findsNothing);
    expect(find.byKey(const Key('admin-email-field')), findsNothing);
    expect(find.byKey(const Key('admin-password-field')), findsNothing);
    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Seed'), findsNothing);
    expect(find.text('Seed sample temples'), findsNothing);
    expect(find.text('Upload'), findsNothing);
    expect(find.text('Create a temple'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(auth.signInCalls, 0);
  });

  testWidgets('AdminScreen shows sign-in when signed out and hides Seed',
      (tester) async {
    final auth = FakeAdminAuth();

    await tester.pumpWidget(
      MaterialApp(home: AdminScreen(adminAuth: auth, isDebug: true)),
    );
    await tester.pump();

    expect(find.text('Admin sign-in required'), findsOneWidget);
    expect(find.byKey(const Key('admin-sign-in-button')), findsOneWidget);
    expect(find.byKey(const Key('admin-email-field')), findsOneWidget);
    expect(find.text('Seed'), findsNothing);
    expect(find.text('Seed sample temples'), findsNothing);
    expect(find.text('Upload'), findsNothing);
    expect(find.text('Create a temple'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('AdminScreen sign-in error is shown and does not open writes',
      (tester) async {
    final auth = FakeAdminAuth()..signInError = Exception('invalid-credential');

    await tester.pumpWidget(
      MaterialApp(home: AdminScreen(adminAuth: auth, isDebug: true)),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('admin-email-field')),
      'admin@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('admin-password-field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('admin-sign-in-button')));
    await tester.pump();

    expect(auth.signInCalls, 1);
    expect(auth.lastEmail, 'admin@example.com');
    expect(find.byKey(const Key('admin-sign-in-error')), findsOneWidget);
    expect(find.text('Seed sample temples'), findsNothing);
  });

  testWidgets('AdminScreen shows not-admin state after sign-in without claim',
      (tester) async {
    final auth = FakeAdminAuth();

    await tester.pumpWidget(
      MaterialApp(home: AdminScreen(adminAuth: auth, isDebug: true)),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('admin-email-field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('admin-password-field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('admin-sign-in-button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Signed in, but not an admin'), findsOneWidget);
    expect(find.byKey(const Key('admin-refresh-claims-button')), findsOneWidget);
    expect(find.text('Seed'), findsNothing);
    expect(find.text('Seed sample temples'), findsNothing);
    expect(find.text('Create a temple'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);

    await tester.tap(find.byKey(const Key('admin-refresh-claims-button')));
    await tester.pump();
    expect(auth.refreshCalls, 1);
  });

  testWidgets('Home debug actions hide Seed until admin, then show it',
      (tester) async {
    final auth = FakeAdminAuth();
    var openedAdmin = 0;
    var seeded = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              DebugHomeAdminActions(
                auth: auth,
                onOpenAdmin: () => openedAdmin++,
                seed: () async {
                  seeded++;
                  return const SeedResult(
                    writtenCount: 1,
                    createdCount: 1,
                    updatedCount: 0,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Admin sign-in'), findsOneWidget);
    expect(find.text('Seed'), findsNothing);

    await tester.tap(find.byKey(const Key('home-admin-sign-in')));
    await tester.pump();
    expect(openedAdmin, 1);

    auth.emit(
      const AdminSession(
        uid: 'uid-1',
        email: 'user@example.com',
        isAdmin: false,
      ),
    );
    await tester.pump();
    expect(find.text('Not admin'), findsOneWidget);
    expect(find.text('Seed'), findsNothing);

    auth.emit(
      const AdminSession(
        uid: 'uid-1',
        email: 'admin@example.com',
        isAdmin: true,
      ),
    );
    await tester.pump();
    expect(find.text('Seed'), findsOneWidget);
    expect(find.text('Admin sign-in'), findsNothing);

    await tester.tap(find.text('Seed'));
    await tester.pump();
    expect(seeded, 1);
  });

  testWidgets(
      'AdminScreen shows sign-in even if the auth stream has not emitted',
      (tester) async {
    final hanging = StreamController<AdminSession>.broadcast();
    addTearDown(hanging.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminScreen(
          adminAuth: _HangingAdminAuth(hanging.stream),
          isDebug: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Admin sign-in required'), findsOneWidget);
    expect(find.byKey(const Key('admin-sign-in-button')), findsOneWidget);
    expect(find.text('Seed'), findsNothing);
  });
}

class _HangingAdminAuth implements AdminAuth {
  _HangingAdminAuth(this.session);

  @override
  final Stream<AdminSession> session;

  @override
  Future<bool> isCurrentUserAdmin() async => false;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refreshClaims() async {}
}
