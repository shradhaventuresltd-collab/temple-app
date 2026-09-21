import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String firestoreRules;
  late String storageRules;

  setUpAll(() {
    firestoreRules = File('firestore.rules').readAsStringSync();
    storageRules = File('storage.rules').readAsStringSync();
  });

  test('Firestore rules allow public temple reads and admin-only writes', () {
    expect(firestoreRules, contains("rules_version = '2'"));
    expect(firestoreRules, contains('match /temples/{templeId}'));
    expect(firestoreRules, contains('allow read: if true'));
    expect(firestoreRules, contains('function isAdmin()'));
    expect(firestoreRules, contains('isValidTempleCreate(request.resource.data)'));
    expect(firestoreRules, contains('isValidTempleUpdate(request.resource.data)'));
    expect(firestoreRules, contains('request.auth.token.admin == true'));
    expect(firestoreRules, isNot(contains('allow write: if true')));
    expect(
      firestoreRules,
      isNot(contains('allow create, update, delete: if isAdmin()')),
    );
  });

  test('Storage rules allow public temple reads and admin-only writes', () {
    expect(storageRules, contains("rules_version = '2'"));
    expect(storageRules, contains('match /temples/{templeId}/{allPaths=**}'));
    expect(storageRules, contains('allow read: if true'));
    expect(storageRules, contains('allow write: if isAdmin()'));
    expect(storageRules, contains('request.auth.token.admin == true'));
    expect(storageRules, isNot(contains('allow write: if true')));
  });

  test('firebase.json points at the checked-in rules files', () {
    final firebaseJson = File('firebase.json').readAsStringSync();
    expect(firebaseJson, contains('"rules": "firestore.rules"'));
    expect(firebaseJson, contains('"rules": "storage.rules"'));
  });
}
