import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/meta_upgrade.dart';
import '../../providers/game_provider.dart';
import '../widgets/retro_widgets.dart';

/// The Hall of Legacy: spend Ancient Coins (earned on prestige) on permanent,
/// cross-run upgrades (P3.1).
class LegacyScreen extends ConsumerWidget {
  const LegacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final coins = game.ancientCoins;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "HALL OF LEGACY",
          style: GoogleFonts.vt323(
            color: Colors.amber,
            fontSize: 24,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Ancient Coin balance.
          RetroPanel(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            backgroundColor: const Color(0xFF0D0D0D),
            borderWidth: 3,
            bevelWidth: 3,
            highlightColor: Colors.cyanAccent.withValues(alpha: 0.2),
            child: Row(
              children: [
                const Icon(FontAwesomeIcons.coins, color: Colors.cyanAccent),
                const SizedBox(width: 12),
                Text(
                  "$coins ANCIENT COINS",
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final u in MetaUpgradeCatalog.all)
                  _UpgradeTile(
                    def: MetaUpgradeCatalog.of(u),
                    level: game.metaLevel(u),
                    coins: coins,
                    onBuy: () =>
                        ref.read(gameProvider.notifier).buyMetaUpgrade(u),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeTile extends StatelessWidget {
  final MetaUpgradeDef def;
  final int level;
  final int coins;
  final VoidCallback onBuy;
  const _UpgradeTile({
    required this.def,
    required this.level,
    required this.coins,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final cost = def.costAt(level);
    final maxed = cost == null;
    final affordable = !maxed && coins >= cost;
    final color = _color(def.type);

    return RetroPanel(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      backgroundColor: Colors.grey[900],
      borderWidth: 2,
      bevelWidth: 2,
      highlightColor: color.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(def.type), color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${def.title.toUpperCase()}  •  LVL $level/${def.maxLevel}",
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            def.description,
            style:
                GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
          ),
          const SizedBox(height: 8),
          RetroProgressBar(
            value: def.maxLevel == 0 ? 0 : level / def.maxLevel,
            progressColor: color,
            height: 10,
            segments: def.maxLevel,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level > 0 ? "Now: ${def.effectLabel(level)}" : "Inactive",
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    if (!maxed)
                      Text(
                        "Next: ${def.effectLabel(level + 1)}",
                        style: GoogleFonts.pixelifySans(
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (maxed)
                Text(
                  "MAX",
                  style: GoogleFonts.vt323(
                    color: Colors.greenAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                RetroButton(
                  backgroundColor: affordable ? Colors.cyanAccent : Colors.grey[800]!,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  onPressed: affordable ? onBuy : () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.coins,
                        size: 12,
                        color: affordable ? Colors.black : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$cost",
                        style: GoogleFonts.vt323(
                          color: affordable ? Colors.black : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _icon(MetaUpgrade u) {
    switch (u) {
      case MetaUpgrade.greed:
        return FontAwesomeIcons.sackDollar;
      case MetaUpgrade.fortune:
        return FontAwesomeIcons.clover;
      case MetaUpgrade.haste:
        return FontAwesomeIcons.bolt;
      case MetaUpgrade.scholar:
        return FontAwesomeIcons.bookOpen;
      case MetaUpgrade.vigor:
        return FontAwesomeIcons.heartPulse;
      case MetaUpgrade.legacy:
        return FontAwesomeIcons.crown;
    }
  }

  Color _color(MetaUpgrade u) {
    switch (u) {
      case MetaUpgrade.greed:
        return Colors.amber;
      case MetaUpgrade.fortune:
        return Colors.greenAccent;
      case MetaUpgrade.haste:
        return Colors.yellowAccent;
      case MetaUpgrade.scholar:
        return Colors.lightBlueAccent;
      case MetaUpgrade.vigor:
        return Colors.redAccent;
      case MetaUpgrade.legacy:
        return Colors.purpleAccent;
    }
  }
}
