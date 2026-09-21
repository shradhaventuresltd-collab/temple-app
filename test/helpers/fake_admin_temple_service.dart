import 'dart:async';

import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/admin_temple_service.dart';
import 'package:temple_app/services/seed_service.dart';

class FakeAdminTempleService implements AdminTempleApi {
  FakeAdminTempleService({List<Temple> initial = const []})
      : _temples = List.of(initial) {
    _controller = StreamController<List<Temple>>.broadcast();
    watchTemples = Stream<List<Temple>>.multi((listener) {
      listener.add(List.unmodifiable(_temples));
      final sub = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = sub.cancel;
    });
  }

  List<Temple> _temples;
  late final StreamController<List<Temple>> _controller;

  @override
  late final Stream<List<Temple>> watchTemples;

  Object? writeError;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int appendImagesCalls = 0;
  Temple? lastCreated;
  Temple? lastUpdated;
  Temple? lastAppendedTemple;
  List<String>? lastAppendedUrls;
  String? lastDeletedId;

  List<Temple> get temples => List.unmodifiable(_temples);

  void emit(List<Temple> temples) {
    _temples = List.of(temples);
    _controller.add(List.unmodifiable(_temples));
  }

  @override
  Future<String> createTemple(Temple temple) async {
    createCalls++;
    lastCreated = temple;
    if (writeError != null) throw writeError!;
    final id = temple.id.isNotEmpty
        ? temple.id
        : templeDocumentId(temple.name);
    final saved = temple.copyWith(id: id);
    _temples = [..._temples, saved];
    _controller.add(List.unmodifiable(_temples));
    return id;
  }

  @override
  Future<void> updateTemple(Temple temple) async {
    updateCalls++;
    lastUpdated = temple;
    if (writeError != null) throw writeError!;
    final index = _temples.indexWhere((t) => t.id == temple.id);
    if (index == -1) {
      _temples = [..._temples, temple];
    } else {
      final next = List<Temple>.from(_temples);
      next[index] = temple;
      _temples = next;
    }
    _controller.add(List.unmodifiable(_temples));
  }

  @override
  Future<Temple> appendTempleImages(
    Temple temple,
    List<String> imageUrls,
  ) async {
    appendImagesCalls++;
    lastAppendedTemple = temple;
    lastAppendedUrls = List.of(imageUrls);
    if (writeError != null) throw writeError!;
    final updated = templeWithAppendedImages(temple, imageUrls);
    lastUpdated = updated;
    final index = _temples.indexWhere((t) => t.id == updated.id);
    if (index == -1) {
      _temples = [..._temples, updated];
    } else {
      final next = List<Temple>.from(_temples);
      next[index] = updated;
      _temples = next;
    }
    _controller.add(List.unmodifiable(_temples));
    return updated;
  }

  @override
  Future<AdminDeleteResult> deleteTemple(String id) async {
    deleteCalls++;
    lastDeletedId = id;
    if (writeError != null) throw writeError!;
    _temples = _temples.where((t) => t.id != id).toList();
    _controller.add(List.unmodifiable(_temples));
    return AdminDeleteResult(docId: id, storageObjectsDeleted: 0);
  }
}
