import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/utils/image_picker_helper.dart';
import 'package:temple_app/widgets/admin_auth_gate.dart';
import 'package:temple_app/widgets/seed_temples_control.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.adminAuth});

  /// Injected in tests. Defaults to [AdminAuth.instance].
  final AdminAuth? adminAuth;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color _saffron = Color(0xFFFF8F00);

  late final AdminAuth _auth = widget.adminAuth ?? AdminAuth.instance;
  late final Stream<AdminSession> _session = _auth.session;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminSession>(
      stream: _session,
      builder: (context, snapshot) {
        final session = snapshot.data ?? AdminSession.signedOut;
        final loading = !snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting;

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
              if (kDebugMode && session.isAdmin)
                const SeedTemplesControl(compact: true, light: true),
              if (session.isSignedIn)
                IconButton(
                  key: const Key('admin-appbar-sign-out'),
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => _auth.signOut(),
                ),
            ],
          ),
          body: loading
              ? const Center(
                  child: CircularProgressIndicator(color: _saffron),
                )
              : !session.isSignedIn
                  ? AdminSignInPanel(auth: _auth)
                  : !session.isAdmin
                      ? AdminNotAuthorizedPanel(
                          auth: _auth,
                          session: session,
                        )
                      : const _AdminTemplesBody(),
        );
      },
    );
  }
}

class _AdminTemplesBody extends StatelessWidget {
  const _AdminTemplesBody();

  static const Color _saffron = Color(0xFFFF8F00);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('temples')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _saffron),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading temples.',
              style: GoogleFonts.poppins(color: Colors.brown.shade700),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: SeedTemplesControl());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _AdminTempleCard(
              docId: doc.id,
              data: doc.data()! as Map<String, dynamic>,
            );
          },
        );
      },
    );
  }
}

class _AdminTempleCard extends StatefulWidget {
  const _AdminTempleCard({required this.docId, required this.data});

  final String docId;
  final Map<String, dynamic> data;

  @override
  State<_AdminTempleCard> createState() => _AdminTempleCardState();
}

class _AdminTempleCardState extends State<_AdminTempleCard> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);
  static const Color _gold = Color(0xFFFFD54F);

  bool _uploading = false;
  double _progress = 0;
  int _uploaded = 0;
  int _total = 0;

  Future<void> _pickAndUpload() async {
    final messenger = ScaffoldMessenger.of(context);

    final isAdmin = await AdminAuth.instance.isCurrentUserAdmin();
    if (!isAdmin) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Uploads require a signed-in admin (custom claim admin: true).',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
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
    final firestore = FirebaseFirestore.instance;
    final newUrls = <String>[];

    try {
      for (final file in files) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final ext = file.extension;
        final ref = storage.ref('temples/${widget.docId}/$ts.$ext');

        final uploadTask = ref.putData(
          Uint8List.fromList(file.bytes),
          SettableMetadata(contentType: 'image/$ext'),
        );

        uploadTask.snapshotEvents.listen((event) {
          if (!mounted) return;
          final fileProgress =
              event.bytesTransferred / event.totalBytes;
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

      await firestore.collection('temples').doc(widget.docId).update({
        'images': FieldValue.arrayUnion(newUrls),
      });

      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${newUrls.length} image(s) uploaded for ${widget.data['name']}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] as String? ?? '';
    final state = widget.data['state'] as String? ?? '';
    final imageUrl = widget.data['imageUrl'] as String? ?? '';
    final images = List<String>.from(widget.data['images'] ?? []);

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
        child: Row(
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
                        child: const Icon(Icons.temple_hindu_rounded,
                            color: _saffron),
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFFFFE0B2),
                      child: const Icon(Icons.temple_hindu_rounded,
                          color: _saffron),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                    state,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.brown.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${images.length} image(s)',
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
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
          ],
        ),
      ),
    );
  }
}
