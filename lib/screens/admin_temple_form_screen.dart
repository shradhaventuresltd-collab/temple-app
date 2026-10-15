import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/services/admin_temple_service.dart';
import 'package:temple_app/services/photo_thumb_encoder.dart';
import 'package:temple_app/services/seed_service.dart';
import 'package:temple_app/services/temple_form_validation.dart';
import 'package:temple_app/services/temple_photo_upload.dart';
import 'package:temple_app/widgets/admin_photo_grid.dart';

class AdminTempleFormScreen extends StatefulWidget {
  const AdminTempleFormScreen({
    super.key,
    required this.adminTemples,
    this.existing,
    this.uploader,
    this.thumbEncoder,
    this.pickImages,
    this.initialDrafts,
  });

  final AdminTempleApi adminTemples;
  final Temple? existing;

  /// Editor photos. When null, drafts come from [existing] photos or legacy
  /// image URLs. Tests pass drafts so tiles can render without the network.
  final List<AdminPhotoDraft>? initialDrafts;

  /// Storage upload. Tests can inject a fake. Defaults to Cloud Storage.
  final TemplePhotoUploader? uploader;

  /// Builds the `_480` thumb before upload. Tests can inject a fake.
  final TemplePhotoThumbEncoder? thumbEncoder;

  /// Multi-image pick. Defaults to [ImagePicker.pickMultiImage] resized to
  /// [kTemplePhotoMaxEdge] at [kTemplePhotoJpegQuality].
  final Future<List<XFile>> Function({required int limit})? pickImages;

  bool get isEditing => existing != null;

  @override
  State<AdminTempleFormScreen> createState() => _AdminTempleFormScreenState();
}

class _AdminTempleFormScreenState extends State<AdminTempleFormScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);

  late final TextEditingController _name;
  late final TextEditingController _state;
  late final TextEditingController _city;
  late final TextEditingController _deity;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _story;
  late final TextEditingController _timings;
  late final TextEditingController _specialities;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;

  late final List<AdminPhotoDraft> _drafts;
  Map<String, String> _fieldErrors = {};
  String? _submitError;
  bool _busy = false;
  bool _picking = false;
  int _draftSerial = 0;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name = TextEditingController(text: t?.name ?? '');
    _state = TextEditingController(text: t?.state ?? '');
    _city = TextEditingController(text: t?.city ?? '');
    _deity = TextEditingController(text: t?.deity ?? '');
    _location = TextEditingController(text: t?.location ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _story = TextEditingController(text: t?.story ?? '');
    _timings = TextEditingController(text: t?.timings ?? '');
    _specialities = TextEditingController(
      text: t?.specialities.join('\n') ?? '',
    );
    _drafts = List<AdminPhotoDraft>.of(
      widget.initialDrafts ?? _initialDrafts(t),
    )..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < _drafts.length; i++) {
      _drafts[i].order = i;
    }
    _latitude = TextEditingController(
      text: t == null || t.latitude == null || t.latitude == 0
          ? ''
          : t.latitude.toString(),
    );
    _longitude = TextEditingController(
      text: t == null || t.longitude == null || t.longitude == 0
          ? ''
          : t.longitude.toString(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _state.dispose();
    _city.dispose();
    _deity.dispose();
    _location.dispose();
    _description.dispose();
    _story.dispose();
    _timings.dispose();
    _specialities.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  List<AdminPhotoDraft> _initialDrafts(Temple? temple) {
    if (temple == null) return [];
    if (temple.photos.isNotEmpty) {
      return AdminPhotoDraft.fromTemplePhotos(temple.photos);
    }
    final urls = temple.galleryImages
        .where((url) => url.trim().isNotEmpty && !isPlaceholderImageUrl(url))
        .take(kMaxTemplePhotos)
        .toList();
    return [
      for (var i = 0; i < urls.length; i++)
        AdminPhotoDraft(id: 'legacy-$i', url: urls[i], order: i),
    ];
  }

  bool get _photosBlockSave => _drafts.any((draft) => draft.blocksSave);

  String? get _photoBlockReason {
    if (_drafts.any((draft) => draft.uploading)) {
      return 'Wait for photo uploads to finish.';
    }
    if (_drafts.any((draft) => draft.failed)) {
      return 'Retry the photos that failed to upload.';
    }
    if (_drafts.any((draft) => draft.needsLicence)) {
      return 'Add a licence to every photo before saving.';
    }
    if (_drafts.any((draft) => draft.needsCredit)) {
      return 'Add a credit for CC-BY and CC-BY-SA photos before saving.';
    }
    if (_drafts.any((draft) => draft.blocksSave)) {
      return 'Finish the photo grid before saving.';
    }
    return null;
  }

  String? _storageDocId() {
    final existing = widget.existing?.id.trim() ?? '';
    if (existing.isNotEmpty) return existing;
    final id = templeDocumentId(_name.text);
    return id.isEmpty ? null : id;
  }

  Future<void> _addPhotos() async {
    if (_busy || _picking) return;
    final remaining = kMaxTemplePhotos - _drafts.length;
    if (remaining <= 0) {
      _snack('A temple can have at most $kMaxTemplePhotos photos.');
      return;
    }
    final docId = _storageDocId();
    if (docId == null) {
      _snack('Enter a temple name before adding photos.');
      return;
    }

    final limit = remaining < kMaxPhotosPerPick ? remaining : kMaxPhotosPerPick;
    setState(() => _picking = true);
    List<XFile> files;
    try {
      final pick = widget.pickImages ?? _pickMultiImage;
      files = await pick(limit: limit);
    } catch (e) {
      if (!mounted) return;
      setState(() => _picking = false);
      _snack('Could not open the photo picker. ${adminWriteErrorMessage(e)}');
      return;
    }
    if (!mounted) return;
    setState(() => _picking = false);
    if (files.isEmpty) return;

    final room = kMaxTemplePhotos - _drafts.length;
    final accepted = files.take(room).toList();
    if (accepted.length < files.length) {
      _snack(
        'Only $kMaxTemplePhotos photos can be saved. Extra picks were skipped.',
      );
    }

    final start = _drafts.length;
    final drafts = <AdminPhotoDraft>[];
    for (final file in accepted) {
      final bytes = await file.readAsBytes();
      drafts.add(
        AdminPhotoDraft(
          id: 'new-${_draftSerial++}',
          bytes: bytes,
          fileName: file.name,
          order: start + drafts.length,
          progress: 0,
          uploading: true,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _drafts.addAll(drafts));
    for (final draft in drafts) {
      await _uploadDraft(draft, docId);
    }
  }

  Future<List<XFile>> _pickMultiImage({required int limit}) {
    final args = templePhotoPickArguments(limit: limit);
    return ImagePicker().pickMultiImage(
      limit: args.limit,
      maxWidth: args.maxWidth,
      maxHeight: args.maxHeight,
      imageQuality: args.imageQuality,
    );
  }

  Future<void> _uploadDraft(AdminPhotoDraft draft, String docId) async {
    final bytes = draft.bytes;
    if (bytes == null) {
      setState(() {
        draft.uploading = false;
        draft.failed = true;
      });
      return;
    }
    final uploader = widget.uploader ?? FirebaseTemplePhotoUploader();
    final encoder =
        widget.thumbEncoder ?? const FlutterTemplePhotoThumbEncoder();
    final extension = photoExtensionFromName(draft.fileName);
    try {
      // The picked file can still carry GPS EXIF. Both objects are a new
      // JPEG from that raster, and the stored name is `.jpg`.
      final fullBytes = await encoder.encodeFull(
        bytes: bytes,
        extension: extension,
      );
      final thumbBytes = await encoder.encode(
        bytes: bytes,
        extension: extension,
      );
      final uploaded = await uploader.upload(
        docId: docId,
        bytes: fullBytes,
        thumbBytes: thumbBytes,
        extension: 'jpg',
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => draft.progress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        draft.url = uploaded.url;
        draft.thumbUrl = uploaded.thumbUrl;
        draft.uploading = false;
        draft.failed = false;
        draft.progress = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        draft.uploading = false;
        draft.failed = true;
        _submitError = 'Upload failed: ${adminWriteErrorMessage(e)}';
      });
    }
  }

  Future<void> _retryDraft(int index) async {
    final docId = _storageDocId();
    if (docId == null) {
      _snack('Enter a temple name before adding photos.');
      return;
    }
    final draft = _drafts[index];
    setState(() {
      draft.failed = false;
      draft.uploading = true;
      draft.progress = 0;
    });
    await _uploadDraft(draft, docId);
  }

  Future<void> _editLicence(int index) async {
    final draft = _drafts[index];
    final selection = await showPhotoLicenceSheet(
      context,
      initialLicence: draft.licence,
      initialCredit: draft.credit,
    );
    if (!mounted || selection == null) return;
    setState(() {
      draft.licence = selection.licence;
      draft.credit = selection.credit;
    });
  }

  void _removeDraft(int index) {
    setState(() {
      _drafts.removeAt(index);
      for (var i = 0; i < _drafts.length; i++) {
        _drafts[i].order = i;
      }
    });
  }

  void _reorderDraft(int from, int to) {
    if (from == to || from < 0 || to < 0) return;
    if (from >= _drafts.length || to >= _drafts.length) return;
    setState(() {
      final draft = _drafts.removeAt(from);
      _drafts.insert(to, draft);
      for (var i = 0; i < _drafts.length; i++) {
        _drafts[i].order = i;
      }
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _save() async {
    if (_busy || _photosBlockSave) return;

    final mirrorUrls = [
      for (final draft in _drafts) draft.url.trim(),
    ].where((url) => url.isNotEmpty);
    final result = validateTempleDraft(
      TempleDraft(
        id: widget.existing?.id ?? '',
        name: _name.text,
        state: _state.text,
        city: _city.text,
        deity: _deity.text,
        location: _location.text,
        description: _description.text,
        story: _story.text,
        timings: _timings.text,
        specialitiesText: _specialities.text,
        imageUrl: mirrorUrls.isEmpty ? '' : mirrorUrls.first,
        imagesText: mirrorUrls.join('\n'),
        latitudeText: _latitude.text,
        longitudeText: _longitude.text,
      ),
    );

    if (!result.isValid) {
      setState(() {
        _fieldErrors = result.errors;
        _submitError = 'Fix the highlighted fields and try again.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _fieldErrors = {};
      _submitError = null;
    });

    late final Temple temple;
    try {
      final mirror = deriveTemplePhotoMirror([
        for (final draft in _drafts) draft.toTemplePhoto(),
      ]);
      temple = result.temple!.copyWith(
        imageUrl: mirror.imageUrl,
        images: mirror.images,
        photos: mirror.photos,
        writePhotos: true,
      );
    } catch (e) {
      setState(() {
        _submitError = adminWriteErrorMessage(e);
      });
      return;
    }

    try {
      if (widget.isEditing) {
        await widget.adminTemples.updateTemple(temple);
      } else {
        await widget.adminTemples.createTemple(temple);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitError = adminWriteErrorMessage(e);
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      appBar: AppBar(
        backgroundColor: _saffron,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isEditing ? 'Edit temple' : 'Create temple',
          style: GoogleFonts.lora(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Same Firestore fields as Seed and the public directory '
                    '(name, state, city, deity, address, story, timings, …).',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _submitError!,
                      key: const Key('admin-temple-form-error'),
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _field(
                    key: const Key('admin-temple-name-field'),
                    controller: _name,
                    label: 'Name',
                    fieldKey: 'name',
                    textInputAction: TextInputAction.next,
                  ),
                  _field(
                    key: const Key('admin-temple-state-field'),
                    controller: _state,
                    label: 'State',
                    hint:
                        'Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, Himachal Pradesh',
                    fieldKey: 'state',
                    textInputAction: TextInputAction.next,
                  ),
                  _field(
                    key: const Key('admin-temple-city-field'),
                    controller: _city,
                    label: 'City',
                    fieldKey: 'city',
                    textInputAction: TextInputAction.next,
                  ),
                  _field(
                    key: const Key('admin-temple-deity-field'),
                    controller: _deity,
                    label: 'Deity',
                    hint: 'Shiva, Vishnu, Devi, Murugan, …',
                    fieldKey: 'deity',
                    textInputAction: TextInputAction.next,
                  ),
                  _field(
                    key: const Key('admin-temple-location-field'),
                    controller: _location,
                    label: 'Location / address',
                    fieldKey: 'location',
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                  ),
                  _field(
                    key: const Key('admin-temple-timings-field'),
                    controller: _timings,
                    label: 'Timings',
                    hint: '5:00 AM – 12:30 PM, 4:00 PM – 10:00 PM',
                    fieldKey: 'timings',
                    textInputAction: TextInputAction.next,
                  ),
                  _field(
                    key: const Key('admin-temple-description-field'),
                    controller: _description,
                    label: 'Description',
                    fieldKey: 'description',
                    maxLines: 4,
                  ),
                  _field(
                    key: const Key('admin-temple-story-field'),
                    controller: _story,
                    label: 'Story',
                    fieldKey: 'story',
                    maxLines: 5,
                  ),
                  _field(
                    key: const Key('admin-temple-specialities-field'),
                    controller: _specialities,
                    label: 'Specialities',
                    hint: 'One per line, or comma-separated',
                    fieldKey: 'specialities',
                    maxLines: 4,
                  ),
                  Text(
                    'Photos',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _deepSaffron,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _drafts.isEmpty
                        ? 'No photos yet. The temple stays Photo pending. '
                              'Seed does not add stock photos.'
                        : 'First photo is the cover. Long-press a tile to reorder. '
                              'Each photo needs a licence before Save.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AdminPhotoGrid(
                    drafts: _drafts,
                    addEnabled: !_busy && !_picking,
                    onAdd: _busy ? null : _addPhotos,
                    onRemove: _removeDraft,
                    onRetry: _retryDraft,
                    onReorder: _reorderDraft,
                    onEditLicence: _editLicence,
                  ),
                  if (_photoBlockReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _photoBlockReason!,
                      key: const Key('admin-photo-save-blocked'),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8D4E00),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          key: const Key('admin-temple-latitude-field'),
                          controller: _latitude,
                          label: 'Latitude',
                          fieldKey: 'latitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          key: const Key('admin-temple-longitude-field'),
                          controller: _longitude,
                          label: 'Longitude',
                          fieldKey: 'longitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('admin-temple-save-button'),
                    onPressed: (_busy || _photosBlockSave) ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _busy
                          ? 'Saving…'
                          : widget.isEditing
                          ? 'Save changes'
                          : 'Create temple',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _saffron,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _saffron.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String fieldKey,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    final error = _fieldErrors[fieldKey];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: controller,
        enabled: !_busy,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          labelStyle: const TextStyle(color: _deepSaffron),
          errorText: error,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: _saffron, width: 1.6),
          ),
        ),
      ),
    );
  }
}
