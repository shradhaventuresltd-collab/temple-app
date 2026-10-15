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
    expect(
      firestoreRules,
      contains('allow create: if isAdmin() && isValidTempleCreate'),
    );
    expect(
      firestoreRules,
      contains('isValidTempleCreate(request.resource.data)'),
    );
    expect(
      firestoreRules,
      contains('isValidTempleUpdate(request.resource.data)'),
    );
    expect(firestoreRules, contains('allow delete: if isAdmin()'));
    expect(firestoreRules, contains("validStringLength('timings', 1, 1000)"));
    expect(firestoreRules, contains('request.auth.token.admin == true'));
    expect(firestoreRules, contains("'photos'"));
    expect(firestoreRules, contains('photos.size() <= 12'));
    expect(firestoreRules, contains('value.size() <= 2000'));
    expect(firestoreRules, contains(r"^https://[^\\s]+$"));
    expect(firestoreRules, contains('photo.credit.size() <= 200'));
    expect(firestoreRules, contains('photo.order is int'));
    expect(firestoreRules, contains('photo.order >= 0'));
    expect(firestoreRules, contains('photo.order <= 11'));
    expect(
      firestoreRules,
      contains("'CC-BY', 'CC-BY-SA', 'CC0', 'Own', 'Permission'"),
    );
    expect(firestoreRules, contains("photo.licence == 'CC-BY'"));
    expect(firestoreRules, contains("photo.licence == 'CC-BY-SA'"));
    expect(firestoreRules, contains('optionalValidPhotos(data)'));
    expect(firestoreRules, contains('function isValidPhoto(photo)'));
    expect(firestoreRules, contains('function coordinatesArePaired(data)'));
    expect(firestoreRules, contains('coordinatesArePaired(data)'));
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

  test('null timings are allowed and an empty timings string is not', () {
    expect(firestoreRules, contains('function validTimings()'));
    expect(firestoreRules, contains('function optionalTimings()'));
    expect(
      firestoreRules,
      contains('request.resource.data.timings == null ||'),
    );
    expect(firestoreRules, contains('validTimings()'));
    expect(firestoreRules, contains('optionalTimings()'));
    expect(firestoreRules, contains("validStringLength('timings', 1, 1000)"));
    expect(firestoreRules, contains("validStringLength('story', 1, 20000)"));
    expect(firestoreRules, isNot(contains("timings == ''")));
    expect(firestoreRules, isNot(contains('timings == ""')));
  });

  test('firebase.json points at the checked-in rules files', () {
    final firebaseJson = File('firebase.json').readAsStringSync();
    expect(firebaseJson, contains('"rules": "firestore.rules"'));
    expect(firebaseJson, contains('"rules": "storage.rules"'));
  });
}
