import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/admin_temple_form_screen.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/admin_temple_service.dart';
import 'package:temple_app/utils/image_picker_helper.dart';
import 'package:temple_app/widgets/admin_auth_gate.dart';
import 'package:temple_app/widgets/seed_temples_control.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.adminAuth, this.adminTemples});

  /// Injected in tests. Defaults to [AdminAuth.instance].
  final AdminAuth? adminAuth;

  /// Injected in tests. Defaults to [AdminTempleService].
  final AdminTempleApi? adminTemples;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color _saffron = Color(0xFFFF8F00);

  late final AdminAuth _auth = widget.adminAuth ?? AdminAuth.instance;
  late final AdminTempleApi _temples =
      widget.adminTemples ?? AdminTempleService();
  late final Stream<AdminSession> _session = _auth.session;

  Future<void> _openForm({Temple? existing}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminTempleFormScreen(
          adminTemples: _temples,
          existing: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminSession>(
      stream: _session,
      initialData: AdminSession.signedOut,
      builder: (context, snapshot) {
        final session = snapshot.data ?? AdminSession.signedOut;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF2),
          appBar: AppBar(
            backgroundColor: _saffron,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Admin Panel',
              style: GoogleFonts.lora(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (kDebugMode && session.isAdmin) ...[
                const SeedTemplesControl(compact: true, light: true),
                IconButton(
                  key: const Key('admin-add-temple-appbar'),
                  tooltip: 'Create temple',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _openForm(),
                ),
              ],
              if (session.isSignedIn)
                IconButton(
                  key: const Key('admin-appbar-sign-out'),
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => _auth.signOut(),
                ),
            ],
          ),
          body: !session.isSignedIn
              ? AdminSignInPanel(auth: _auth)
              : !session.isAdmin
                  ? AdminNotAuthorizedPanel(
                      auth: _auth,
                      session: session,
                    )
                  : _AdminTemplesBody(
                      adminTemples: _temples,
                      onCreate: () => _openForm(),
                      onEdit: (temple) => _openForm(existing: temple),
                    ),
        );
      },
    );
  }
}

class _AdminTemplesBody extends StatelessWidget {
  const _AdminTemplesBody({
    required this.adminTemples,
    required this.onCreate,
    required this.onEdit,
  });

  final AdminTempleApi adminTemples;
  final VoidCallback onCreate;
  final ValueChanged<Temple> onEdit;

  static const Color _saffron = Color(0xFFFF8F00);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Center(
        child: Text(
          'Admin CMS is available in debug builds only.',
          style: GoogleFonts.poppins(color: Colors.brown.shade700),
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<List<Temple>>(
      stream: adminTemples.watchTemples,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _saffron),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                adminWriteErrorMessage(snapshot.error!),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.brown.shade700),
              ),
            ),
          );
        }

        final temples = snapshot.data ?? [];

        if (temples.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SeedTemplesControl(),
                  const SizedBox(height: 20),
                  Text(
                    'or',
                    style: GoogleFonts.poppins(
                      color: Colors.brown.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('admin-add-temple-button'),
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Create a temple',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _saffron,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
              itemCount: temples.length,
              itemBuilder: (context, index) {
                final temple = temples[index];
                return _AdminTempleCard(
                  temple: temple,
                  adminTemples: adminTemples,
                  onEdit: () => onEdit(temple),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                key: const Key('admin-add-temple-fab'),
                onPressed: onCreate,
                backgroundColor: _saffron,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add temple',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminTempleCard extends StatefulWidget {
  const _AdminTempleCard({
    required this.temple,
    required this.adminTemples,
    required this.onEdit,
  });

  final Temple temple;
  final AdminTempleApi adminTemples;
  final VoidCallback onEdit;

  @override
  State<_AdminTempleCard> createState() => _AdminTempleCardState();
}

class _AdminTempleCardState extends State<_AdminTempleCard> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);
  static const Color _gold = Color(0xFFFFD54F);

  bool _uploading = false;
  bool _deleting = false;
  double _progress = 0;
  int _uploaded = 0;
  int _total = 0;

  Temple get temple => widget.temple;

  void _snack(String text, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, style: GoogleFonts.poppins()),
          backgroundColor:
              isError ? Colors.red.shade700 : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _pickAndUpload() async {
    final isAdmin = await AdminAuth.instance.isCurrentUserAdmin();
    if (!isAdmin) {
      _snack(
        'Uploads require a signed-in admin (custom claim admin: true).',
        isError: true,
      );
      return;
    }

    final files = await pickImageFiles();
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _progress = 0;
      _uploaded = 0;
      _total = files.length;
    });

    final storage = FirebaseStorage.instance;
    final newUrls = <String>[];

    try {
      for (final file in files) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final ext = file.extension;
        final ref = storage.ref('temples/${temple.id}/$ts.$ext');

        final uploadTask = ref.putData(
          Uint8List.fromList(file.bytes),
          SettableMetadata(contentType: 'image/$ext'),
        );

        uploadTask.snapshotEvents.listen((event) {
          if (!mounted) return;
          final fileProgress = event.bytesTransferred / event.totalBytes;
          setState(() {
            _progress = (_uploaded + fileProgress) / _total;
          });
        });

        await uploadTask;
        final url = await ref.getDownloadURL();
        newUrls.add(url);

        _uploaded++;
        if (mounted) {
          setState(() => _progress = _uploaded / _total);
        }
      }

      // Full temple payload — not images-only update/arrayUnion — so
      // Firestore rules that validate request.resource.data can succeed.
      await widget.adminTemples.appendTempleImages(temple, newUrls);

      if (!mounted) return;
      setState(() => _uploading = false);
      _snack(
        '${newUrls.length} image(s) uploaded for ${temple.name}',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _snack('Upload failed: ${adminWriteErrorMessage(e)}', isError: true);
    }
  }

  Future<void> _confirmDelete() async {
    if (_deleting || _uploading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete temple?',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Permanently remove "${temple.name}" from Firestore? '
            'Images uploaded under temples/${temple.id}/ in Storage will '
            'also be deleted. External image URLs (for example seed photos) '
            'are not Storage files and are left as-is.',
            style: GoogleFonts.poppins(height: 1.45),
          ),
          actions: [
            TextButton(
              key: const Key('admin-delete-cancel-button'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('admin-delete-confirm-button'),
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final result = await widget.adminTemples.deleteTemple(temple.id);
      if (!mounted) return;
      _snack(result.successMessage, isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _snack(adminWriteErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = temple.imageUrl;
    final busy = _uploading || _deleting;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(
                            width: 72,
                            height: 72,
                            color: const Color(0xFFFFE0B2),
                            child: const Icon(
                              Icons.temple_hindu_rounded,
                              color: _saffron,
                            ),
                          ),
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFFFFE0B2),
                          child: const Icon(
                            Icons.temple_hindu_rounded,
                            color: _saffron,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        temple.name,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _deepSaffron,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (temple.city.isNotEmpty) temple.city,
                          temple.state,
                        ].where((s) => s.isNotEmpty).join(', '),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.brown.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${temple.images.length} image(s)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.brown.shade400,
                        ),
                      ),
                      if (_uploading) ...[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: const Color(0xFFFFE0B2),
                          color: _saffron,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_uploaded / $_total uploaded',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.brown.shade400,
                          ),
                        ),
                      ],
                      if (_deleting) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Deleting…',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: busy ? null : _pickAndUpload,
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: Text(
                    _uploading ? 'Uploading' : 'Upload',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saffron,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  key: Key('admin-edit-temple-${temple.id}'),
                  onPressed: busy ? null : widget.onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  key: Key('admin-delete-temple-${temple.id}'),
                  onPressed: busy ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    'Delete',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
