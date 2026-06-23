import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/offline_service.dart';
import '../widgets/retro_widgets.dart';

/// "While you were away" summary, shown on return when offline catch-up
/// actually did something (see [OfflineReport.isMeaningful]).
class WelcomeBackDialog extends StatelessWidget {
  final OfflineReport report;
  const WelcomeBackDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: RetroPanel(
        backgroundColor: const Color(0xFF1A1A1A),
        borderWidth: 3,
        bevelWidth: 3,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "WELCOME BACK",
                style: GoogleFonts.vt323(
                  color: Colors.amber,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                "AWAY FOR ${_formatDuration(report.awayFor)}".toUpperCase(),
                style: GoogleFonts.pixelifySans(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
            const RetroDivider(color: Colors.black, height: 24, thickness: 2),

            if (report.totalHpHealed > 0)
              _row(
                icon: FontAwesomeIcons.heart,
                iconColor: Colors.redAccent,
                label: report.hpHealedByHero.length == 1
                    ? "${report.hpHealedByHero.keys.first} recovered"
                    : "Party recovered",
                value: "+${report.totalHpHealed} HP",
              ),

            if (report.businessGold > 0)
              _row(
                icon: FontAwesomeIcons.coins,
                iconColor: Colors.amber,
                label: "Your enterprise earned",
                value: "+${report.businessGold} G",
              ),

            if (report.businessItems > 0)
              _row(
                icon: FontAwesomeIcons.boxOpen,
                iconColor: Colors.lightBlueAccent,
                label: "Goods produced",
                value: "+${report.businessItems}",
              ),

            if (report.businessQuests > 0)
              _row(
                icon: FontAwesomeIcons.scroll,
                iconColor: Colors.greenAccent,
                label: "Bounties scouted",
                value: "+${report.businessQuests}",
              ),

            const SizedBox(height: 20),
            RetroButton(
              backgroundColor: Colors.amber[600],
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "CONTINUE",
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.pixelifySans(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.vt323(
              color: iconColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    if (d.inDays >= 1) {
      final h = d.inHours % 24;
      return h > 0 ? "${d.inDays}d ${h}h" : "${d.inDays}d";
    }
    if (d.inHours >= 1) {
      final m = d.inMinutes % 60;
      return m > 0 ? "${d.inHours}h ${m}m" : "${d.inHours}h";
    }
    return "${d.inMinutes}m";
  }
}
