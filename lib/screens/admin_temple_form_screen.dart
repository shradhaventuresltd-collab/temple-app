import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/admin_temple_service.dart';
import 'package:temple_app/services/temple_form_validation.dart';

class AdminTempleFormScreen extends StatefulWidget {
  const AdminTempleFormScreen({
    super.key,
    required this.adminTemples,
    this.existing,
  });

  final AdminTempleApi adminTemples;
  final Temple? existing;

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
  late final TextEditingController _imageUrl;
  late final TextEditingController _images;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;

  Map<String, String> _fieldErrors = {};
  String? _submitError;
  bool _busy = false;

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
    _imageUrl = TextEditingController(text: t?.imageUrl ?? '');
    _images = TextEditingController(text: t?.images.join('\n') ?? '');
    _latitude = TextEditingController(
      text: t == null || t.latitude == 0 ? '' : t.latitude.toString(),
    );
    _longitude = TextEditingController(
      text: t == null || t.longitude == 0 ? '' : t.longitude.toString(),
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
    _imageUrl.dispose();
    _images.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;

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
        imageUrl: _imageUrl.text,
        imagesText: _images.text,
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

    try {
      if (widget.isEditing) {
        await widget.adminTemples.updateTemple(result.temple!);
      } else {
        await widget.adminTemples.createTemple(result.temple!);
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
                hint: 'Tamil Nadu, Kerala, Karnataka, …',
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
              _field(
                key: const Key('admin-temple-image-url-field'),
                controller: _imageUrl,
                label: 'Cover image URL',
                hint: 'https://…',
                fieldKey: 'imageUrl',
                textInputAction: TextInputAction.next,
              ),
              _field(
                key: const Key('admin-temple-images-field'),
                controller: _images,
                label: 'Gallery image URLs',
                hint:
                    'One URL per line. File upload stays on the Admin list '
                    '(web picker).',
                fieldKey: 'images',
                maxLines: 4,
              ),
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
                onPressed: _busy ? null : _save,
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
