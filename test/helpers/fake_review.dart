import 'package:temple_app/services/review_prompt.dart';
import 'package:temple_app/services/temple_share.dart';

class FakeReviewClient implements ReviewClient {
  FakeReviewClient({
    this.available = true,
    this.availableError,
    this.requestError,
  });

  bool available;
  Object? availableError;
  Object? requestError;
  int availabilityChecks = 0;
  int requests = 0;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks += 1;
    final error = availableError;
    if (error != null) throw error;
    return available;
  }

  @override
  Future<void> requestReview() async {
    requests += 1;
    final error = requestError;
    if (error != null) throw error;
  }
}

/// Throws on every call.
class ThrowingReviewPromptStore implements ReviewPromptStore {
  @override
  Future<DateTime?> readLastPrompt() => throw StateError('prefs read');

  @override
  Future<int> readSessionCount() => throw StateError('prefs read');

  @override
  Future<void> writeLastPrompt(DateTime at) => throw StateError('prefs write');

  @override
  Future<void> writeSessionCount(int count) => throw StateError('prefs write');

  @override
  Future<bool> readSessionDeferred() => throw StateError('prefs read');

  @override
  Future<void> writeSessionDeferred(bool deferred) =>
      throw StateError('prefs write');
}

class FakeTempleSharer extends TempleSharer {
  FakeTempleSharer({this.error, this.hold, this.opens = true});

  Object? error;

  /// When set, each share waits on it, like a share sheet that is open.
  Future<void>? hold;

  /// False: the sheet reports it could not open.
  bool opens;

  final List<String> texts = [];
  final List<String?> subjects = [];

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    texts.add(text);
    subjects.add(subject);
    final pending = hold;
    if (pending != null) await pending;
    final failure = error;
    if (failure != null) throw failure;
    return opens;
  }
}

class FakeWhatsAppLauncher extends WhatsAppLauncher {
  FakeWhatsAppLauncher({
    this.installed = true,
    this.opens = true,
    this.checkError,
    this.openError,
    this.hold,
  });

  bool installed;
  bool opens;
  Object? checkError;
  Object? openError;
  Future<void>? hold;
  int checks = 0;
  final List<String> texts = [];

  @override
  Future<bool> isInstalled() async {
    checks += 1;
    final error = checkError;
    if (error != null) throw error;
    return installed;
  }

  @override
  Future<bool> open(String text) async {
    texts.add(text);
    final pending = hold;
    if (pending != null) await pending;
    final error = openError;
    if (error != null) throw error;
    return opens;
  }
}
