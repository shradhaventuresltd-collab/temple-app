import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple_photo.dart';

/// In-progress or saved photo in the admin editor.
class AdminPhotoDraft {
  AdminPhotoDraft({
    required this.id,
    this.url = '',
    this.thumbUrl,
    this.credit = '',
    this.licence,
    this.order = 0,
    this.bytes,
    this.fileName = 'photo.jpg',
    this.progress = 1,
    this.uploading = false,
    this.failed = false,
  });

  final String id;
  String url;

  /// Download URL of the `_480` object, when this draft has one.
  String? thumbUrl;
  String credit;
  PhotoLicence? licence;
  int order;
  Uint8List? bytes;
  String fileName;
  double progress;
  bool uploading;
  bool failed;

  bool get needsLicence => licence == null;

  bool get needsCredit =>
      licence != null && licence!.requiresCredit && credit.trim().isEmpty;

  bool get blocksSave =>
      uploading ||
      failed ||
      needsLicence ||
      needsCredit ||
      url.trim().isEmpty ||
      credit.length > kMaxPhotoCreditLength;

  TemplePhoto toTemplePhoto() {
    return TemplePhoto(
      url: url.trim(),
      credit: credit.trim(),
      licence: licence,
      order: order,
      thumbUrl: thumbUrl,
    );
  }

  static List<AdminPhotoDraft> fromTemplePhotos(List<TemplePhoto> photos) {
    final indexed = [for (var i = 0; i < photos.length; i++) i];
    indexed.sort((a, b) {
      final byOrder = photos[a].order.compareTo(photos[b].order);
      if (byOrder != 0) return byOrder;
      return a.compareTo(b);
    });
    return [
      for (var slot = 0; slot < indexed.length; slot++)
        AdminPhotoDraft(
          id: 'photo-$slot-${photos[indexed[slot]].url.hashCode}',
          url: photos[indexed[slot]].url,
          thumbUrl: photos[indexed[slot]].thumbUrl,
          credit: photos[indexed[slot]].credit,
          licence: photos[indexed[slot]].licence,
          order: slot,
        ),
    ];
  }
}

class PhotoLicenceSelection {
  const PhotoLicenceSelection({required this.licence, required this.credit});

  final PhotoLicence licence;
  final String credit;
}

/// 3-column photo grid. The first tile is the cover.
class AdminPhotoGrid extends StatelessWidget {
  const AdminPhotoGrid({
    super.key,
    required this.drafts,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
    required this.onReorder,
    required this.onEditLicence,
    this.addEnabled = true,
  });

  final List<AdminPhotoDraft> drafts;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onRetry;
  final void Function(int from, int to) onReorder;
  final ValueChanged<int> onEditLicence;
  final bool addEnabled;

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _amberInk = Color(0xFF8D4E00);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const gap = 8.0;
        final tile = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final showAdd = drafts.length < kMaxTemplePhotos;
        return Wrap(
          key: const Key('admin-photo-grid'),
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < drafts.length; index++)
              SizedBox(
                width: tile,
                height: tile,
                child: _PhotoTile(
                  index: index,
                  draft: drafts[index],
                  onRemove: () => onRemove(index),
                  onRetry: () => onRetry(index),
                  onEditLicence: () => onEditLicence(index),
                  onReorder: onReorder,
                ),
              ),
            if (showAdd)
              SizedBox(
                width: tile,
                height: tile,
                child: _AddPhotoTile(
                  enabled: addEnabled && onAdd != null,
                  onPressed: onAdd,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('admin-photo-add'),
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminPhotoGrid._saffron, width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AdminPhotoGrid._saffron,
                ),
                const SizedBox(height: 4),
                Text(
                  '+ Add photo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onRetry,
    required this.onEditLicence,
    required this.onReorder,
  });

  final int index;
  final AdminPhotoDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final VoidCallback onEditLicence;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    final tile = _tileBody();
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 96, height: 96, child: _preview()),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: tile),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted
                    ? AdminPhotoGrid._saffron
                    : const Color(0xFFFFD54F),
                width: highlighted ? 2 : 1,
              ),
            ),
            child: tile,
          ),
        );
      },
    );
  }

  Widget _tileBody() {
    return ClipRRect(
      key: Key('admin-photo-tile-$index'),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: const Color(0xFFFFF8EE),
            child: InkWell(
              key: Key('admin-photo-licence-$index'),
              onTap: draft.uploading ? null : onEditLicence,
              child: _preview(),
            ),
          ),
          if (index == 0)
            const Positioned(left: 4, top: 4, child: _CoverChip()),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              key: Key('admin-photo-remove-$index'),
              tooltip: 'Remove photo',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
          if (draft.uploading)
            Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: LinearProgressIndicator(
                key: Key('admin-photo-progress-$index'),
                value: draft.progress <= 0 ? null : draft.progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFFFE0B2),
                color: AdminPhotoGrid._saffron,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          if (draft.failed)
            Center(
              child: TextButton(
                key: Key('admin-photo-retry-$index'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade800,
                ),
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (!draft.uploading && !draft.failed) _statusBadge(),
        ],
      ),
    );
  }

  Widget _preview() {
    final bytes = draft.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PhotoFallback(),
      );
    }
    final url = draft.url.trim();
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PhotoFallback(),
        errorWidget: (_, _, _) => const _PhotoFallback(),
      );
    }
    return const _PhotoFallback();
  }

  Widget _statusBadge() {
    if (draft.needsLicence) {
      return Positioned(
        left: 4,
        right: 4,
        bottom: 4,
        child: _Badge(
          key: Key('admin-photo-needs-licence-$index'),
          label: 'Needs licence',
        ),
      );
    }
    if (draft.needsCredit) {
      return Positioned(
        left: 4,
        right: 4,
        bottom: 4,
        child: _Badge(
          key: Key('admin-photo-needs-credit-$index'),
          label: 'Needs credit',
        ),
      );
    }
    final licence = draft.licence;
    if (licence == null) return const SizedBox.shrink();
    return Positioned(
      left: 4,
      right: 4,
      bottom: 4,
      child: _Badge(
        key: Key('admin-photo-licence-badge-$index'),
        label: licence.wireValue,
        filled: false,
      ),
    );
  }
}

class _CoverChip extends StatelessWidget {
  const _CoverChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('admin-photo-cover-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Cover',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.label, this.filled = true});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? AdminPhotoGrid._amber : Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: AdminPhotoGrid._amberInk,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFE0B2),
      child: Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF8F00)),
    );
  }
}

/// Bottom sheet with the five licences and a credit field.
Future<PhotoLicenceSelection?> showPhotoLicenceSheet(
  BuildContext context, {
  PhotoLicence? initialLicence,
  String initialCredit = '',
}) {
  return showModalBottomSheet<PhotoLicenceSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFFFFBF2),
    builder: (context) {
      return _PhotoLicenceSheet(
        initialLicence: initialLicence,
        initialCredit: initialCredit,
      );
    },
  );
}

class _PhotoLicenceSheet extends StatefulWidget {
  const _PhotoLicenceSheet({
    required this.initialLicence,
    required this.initialCredit,
  });

  final PhotoLicence? initialLicence;
  final String initialCredit;

  @override
  State<_PhotoLicenceSheet> createState() => _PhotoLicenceSheetState();
}

class _PhotoLicenceSheetState extends State<_PhotoLicenceSheet> {
  late PhotoLicence? _licence = widget.initialLicence;
  late final TextEditingController _credit = TextEditingController(
    text: widget.initialCredit,
  );

  @override
  void dispose() {
    _credit.dispose();
    super.dispose();
  }

  bool get _creditRequired => _licence?.requiresCredit ?? false;

  bool get _canApply {
    final licence = _licence;
    if (licence == null) return false;
    final credit = _credit.text.trim();
    if (credit.length > kMaxPhotoCreditLength) return false;
    if (licence.requiresCredit && credit.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        key: const Key('admin-photo-licence-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Photo licence',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CC-BY and CC-BY-SA need a credit. CC0, Own, and Permission '
            'can leave credit blank.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: Colors.brown.shade600,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<PhotoLicence>(
            groupValue: _licence,
            onChanged: (value) => setState(() => _licence = value),
            child: Column(
              children: [
                for (final licence in PhotoLicence.values)
                  RadioListTile<PhotoLicence>(
                    key: Key('admin-photo-licence-option-${licence.wireValue}'),
                    value: licence,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFFF8F00),
                    title: Text(
                      licence.wireValue,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      licence.requiresCredit
                          ? 'Credit required'
                          : 'Credit optional',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          TextField(
            key: const Key('admin-photo-licence-credit'),
            controller: _credit,
            maxLength: kMaxPhotoCreditLength,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _creditRequired ? 'Credit (required)' : 'Credit',
              hintText: 'Photographer or source',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('admin-photo-licence-apply'),
            onPressed: _canApply
                ? () {
                    final licence = _licence;
                    if (licence == null) return;
                    Navigator.pop(
                      context,
                      PhotoLicenceSelection(
                        licence: licence,
                        credit: _credit.text.trim(),
                      ),
                    );
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8F00),
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            child: Text(
              'Use this licence',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
