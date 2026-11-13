import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/utils/place_sources.dart';
import 'package:temple_app/widgets/unverified_source_notice.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dress-code source footer (KAN-203 §2.5). KAN-197 typography is kept:
/// Poppins 11.5, muted prefix / commas / "+N more" chrome, accent underlined
/// names, 48dp minimum tap height.
class SourceAttributionFooter extends StatefulWidget {
  const SourceAttributionFooter({
    super.key,
    required this.sources,
    this.footerKey = const Key('detail-dress-code-source'),
  });

  final List<PlaceSource> sources;
  final Key footerKey;

  @override
  State<SourceAttributionFooter> createState() =>
      _SourceAttributionFooterState();
}

class _SourceAttributionFooterState extends State<SourceAttributionFooter> {
  var _opening = false;

  Future<void> _open(Uri uri) async {
    if (_opening) return;
    _opening = true;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    } finally {
      _opening = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(UnverifiedSourceNotice.launchFailedText),
          ),
        );
    }
  }

  void _openRemaining(PlaceSourceFooterLayout layout) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          key: const Key('detail-dress-code-source-sheet'),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (var i = 0; i < layout.remaining.length; i++)
                ListTile(
                  key: Key(
                    'detail-dress-code-source-sheet-${layout.visible.length + i}',
                  ),
                  title: Text(layout.remaining[i].label),
                  subtitle: Text(layout.remaining[i].hostLabel),
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_open(layout.remaining[i].uri));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DetailUxTokens.of(context);
    final layout = placeSourceFooterLayout(widget.sources);
    final chrome = GoogleFonts.poppins(
      fontSize: 11.5,
      height: 1.4,
      color: tokens.muted,
    );
    final link = chrome.copyWith(
      color: tokens.accent,
      decoration: TextDecoration.underline,
      decorationColor: tokens.accent,
    );

    return DefaultTextStyle(
      key: widget.footerKey,
      style: chrome,
      child: layout.visible.isEmpty
          ? Text(compiledFromPublicSources, style: chrome)
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(layout.prefix, style: chrome),
                for (var i = 0; i < layout.visible.length; i++) ...[
                  if (i > 0) Text(', ', style: chrome),
                  _SourceTap(
                    label: layout.visible[i].label,
                    style: link,
                    onTap: () => _open(layout.visible[i].uri),
                    linkKey: Key('detail-dress-code-source-link-$i'),
                  ),
                ],
                if (layout.moreCount > 0) ...[
                  Text(' ', style: chrome),
                  _SourceTap(
                    label: '+${layout.moreCount} more',
                    style: chrome,
                    onTap: () => _openRemaining(layout),
                    linkKey: const Key('detail-dress-code-source-more'),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SourceTap extends StatelessWidget {
  const _SourceTap({
    required this.label,
    required this.style,
    required this.onTap,
    required this.linkKey,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;
  final Key linkKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      link: true,
      label: label,
      child: InkWell(
        key: linkKey,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
