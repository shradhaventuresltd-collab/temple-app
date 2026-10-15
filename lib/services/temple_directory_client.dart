import 'package:cloud_firestore/cloud_firestore.dart';

/// One Firestore document, detached from the plugin snapshot type.
class DirectoryDoc {
  const DirectoryDoc({required this.id, required this.exists, this.data});

  final String id;
  final bool exists;
  final Map<String, dynamic>? data;
}

/// Reads the directory uses. A null [source] is the Firestore default
/// (`serverAndCache`).
abstract class TempleDirectoryClient {
  Future<DirectoryDoc> getDoc(String collection, String id, {Source? source});

  Future<List<DirectoryDoc>> getDocs(
    String collection, {
    required Source source,
  });

  /// Documents in [collection] whose [field] equals [value]. One state, not
  /// the whole directory.
  Future<List<DirectoryDoc>> getDocsWhere(
    String collection, {
    required String field,
    required String value,
    required Source source,
  });
}

/// Live Firestore reads for [TempleDirectoryClient].
class FirestoreTempleDirectoryClient implements TempleDirectoryClient {
  FirestoreTempleDirectoryClient(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DirectoryDoc> getDoc(
    String collection,
    String id, {
    Source? source,
  }) async {
    final snap = await _firestore
        .collection(collection)
        .doc(id)
        .get(source == null ? const GetOptions() : GetOptions(source: source));
    return DirectoryDoc(id: snap.id, exists: snap.exists, data: snap.data());
  }

  @override
  Future<List<DirectoryDoc>> getDocs(
    String collection, {
    required Source source,
  }) async {
    final snapshot = await _firestore
        .collection(collection)
        .get(GetOptions(source: source));
    return [
      for (final doc in snapshot.docs)
        DirectoryDoc(id: doc.id, exists: true, data: doc.data()),
    ];
  }

  @override
  Future<List<DirectoryDoc>> getDocsWhere(
    String collection, {
    required String field,
    required String value,
    required Source source,
  }) async {
    final snapshot = await _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get(GetOptions(source: source));
    return [
      for (final doc in snapshot.docs)
        DirectoryDoc(id: doc.id, exists: true, data: doc.data()),
    ];
  }
}
