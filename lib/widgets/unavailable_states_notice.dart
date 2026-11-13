import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/services/firestore_read_log.dart';

/// Shown when a shard could not be loaded. That state is omitted.
class UnavailableStatesNotice extends StatelessWidget {
  const UnavailableStatesNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final message = FirestoreReadLog.instance.unavailableShardsMessageOf(
      context.l10n,
    );
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        message,
        key: const Key('unavailable-states-notice'),
        style: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.4,
          color: Colors.red.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
