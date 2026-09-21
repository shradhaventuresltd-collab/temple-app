import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/admin_screen.dart';
import 'package:temple_app/screens/admin_temple_form_screen.dart';
import 'package:temple_app/services/admin_auth.dart';

import 'helpers/fake_admin_auth.dart';
import 'helpers/fake_admin_temple_service.dart';

Temple _temple() {
  return const Temple(
    id: 'test-temple',
    name: 'Test Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: '',
    description: 'A test shrine',
    story: 'Story',
    location: 'Madurai Main',
    timings: '6:00 AM – 8:00 PM',
    specialities: ['Test chip'],
    latitude: 9.9,
    longitude: 78.1,
  );
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required FakeAdminTempleService api,
  Temple? existing,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AdminTempleFormScreen(
        adminTemples: api,
        existing: existing,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpAdmin(
  WidgetTester tester, {
  required FakeAdminAuth auth,
  required FakeAdminTempleService api,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AdminScreen(adminAuth: auth, adminTemples: api),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('empty required fields show errors and do not write',
      (tester) async {
    final api = FakeAdminTempleService();

    await _pumpForm(tester, api: api);

    await tester.ensureVisible(
      find.byKey(const Key('admin-temple-save-button')),
    );
    await tester.tap(find.byKey(const Key('admin-temple-save-button')));
    await tester.pump();

    expect(api.createCalls, 0);
    expect(find.byKey(const Key('admin-temple-form-error')), findsOneWidget);
    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Location / address is required.'), findsOneWidget);
  });

  testWidgets('valid create calls the CMS service', (tester) async {
    final api = FakeAdminTempleService();

    await _pumpForm(tester, api: api);

    await tester.enterText(
      find.byKey(const Key('admin-temple-name-field')),
      'New Shore Temple',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-state-field')),
      'Tamil Nadu',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-city-field')),
      'Mahabalipuram',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-deity-field')),
      'Shiva',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-location-field')),
      'Mahabalipuram, Tamil Nadu',
    );
    await tester.ensureVisible(
      find.byKey(const Key('admin-temple-save-button')),
    );
    await tester.tap(find.byKey(const Key('admin-temple-save-button')));
    await tester.pump();

    expect(api.createCalls, 1);
    expect(api.lastCreated!.name, 'New Shore Temple');
    expect(api.lastCreated!.deity, 'Shiva');
    expect(api.lastCreated!.location, 'Mahabalipuram, Tamil Nadu');
  });

  testWidgets('failed write shows the service error', (tester) async {
    final api = FakeAdminTempleService()
      ..writeError = Exception('permission-denied');

    await _pumpForm(tester, api: api);

    await tester.enterText(
      find.byKey(const Key('admin-temple-name-field')),
      'New Shore Temple',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-state-field')),
      'Tamil Nadu',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-city-field')),
      'Mahabalipuram',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-deity-field')),
      'Shiva',
    );
    await tester.enterText(
      find.byKey(const Key('admin-temple-location-field')),
      'Mahabalipuram',
    );
    await tester.ensureVisible(
      find.byKey(const Key('admin-temple-save-button')),
    );
    await tester.tap(find.byKey(const Key('admin-temple-save-button')));
    await tester.pump();

    expect(find.byKey(const Key('admin-temple-form-error')), findsOneWidget);
    expect(find.text('permission-denied'), findsOneWidget);
    expect(find.text('Create temple'), findsWidgets);
  });

  testWidgets('edit form saves updates to the existing id', (tester) async {
    final api = FakeAdminTempleService(initial: [_temple()]);

    await _pumpForm(tester, api: api, existing: _temple());

    expect(find.text('Edit temple'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('admin-temple-timings-field')),
      '5:00 AM – 9:00 PM',
    );
    await tester.ensureVisible(
      find.byKey(const Key('admin-temple-save-button')),
    );
    await tester.tap(find.byKey(const Key('admin-temple-save-button')));
    await tester.pump();

    expect(api.updateCalls, 1);
    expect(api.lastUpdated!.id, 'test-temple');
    expect(api.lastUpdated!.timings, '5:00 AM – 9:00 PM');
    expect(api.createCalls, 0);
  });

  testWidgets('signed-in admin sees CMS actions; list refreshes after create',
      (tester) async {
    final auth = FakeAdminAuth(
      initial: const AdminSession(
        uid: 'uid-1',
        email: 'admin@example.com',
        isAdmin: true,
      ),
    );
    final api = FakeAdminTempleService();

    await _pumpAdmin(tester, auth: auth, api: api);

    expect(find.text('Create a temple'), findsOneWidget);
    expect(find.byKey(const Key('admin-add-temple-appbar')), findsOneWidget);
    expect(find.text('Upload'), findsNothing);

    await tester.tap(find.text('Create a temple'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AdminTempleFormScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump();

    api.emit([_temple()]);
    await tester.pump();

    expect(find.text('Test Temple'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.byKey(const Key('admin-add-temple-fab')), findsOneWidget);
  });

  testWidgets('delete requires confirm and then removes the temple',
      (tester) async {
    final auth = FakeAdminAuth(
      initial: const AdminSession(
        uid: 'uid-1',
        email: 'admin@example.com',
        isAdmin: true,
      ),
    );
    final api = FakeAdminTempleService(initial: [_temple()]);

    await _pumpAdmin(tester, auth: auth, api: api);

    await tester.tap(find.byKey(const Key('admin-delete-temple-test-temple')));
    await tester.pump();
    expect(find.text('Delete temple?'), findsOneWidget);
    expect(api.deleteCalls, 0);

    await tester.tap(find.byKey(const Key('admin-delete-cancel-button')));
    await tester.pump();
    expect(api.deleteCalls, 0);
    expect(find.text('Test Temple'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-delete-temple-test-temple')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-delete-confirm-button')));
    await tester.pump();

    expect(api.deleteCalls, 1);
    expect(api.lastDeletedId, 'test-temple');
    expect(find.text('Test Temple'), findsNothing);
  });
}
