import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/game_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/daily_provider.dart';
import 'daily_sheet.dart';

class StageSection extends ConsumerWidget {
  const StageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final heroes = ref.watch(heroProvider);
    ref.watch(dailyProvider);
    final hasDailyClaim = ref.read(dailyProvider.notifier).hasClaimable;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gold counter
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/icons/gold_icon_small.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GOLD',
                      style: GoogleFonts.cinzel(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(blurRadius: 4, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${gameState.gold}',
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [const Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ],
            ),

            // Daily goals (Center)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.calendarDay,
                        color: Colors.amber,
                        size: 22,
                      ),
                      tooltip: 'Daily',
                      onPressed: () => showDailySheet(context, ref),
                    ),
                    if (hasDailyClaim)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                // Debug Theme Cycle
                IconButton(
                  icon: const Icon(Icons.color_lens, color: Colors.white24),
                  onPressed: () {
                    ref.read(gameProvider.notifier).debugCycleEra();
                  },
                ),
              ],
            ),

            // Mercenaries counter
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MERCENARIES',
                  style: GoogleFonts.cinzel(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [const Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
                Text(
                  '${heroes.length}/5',
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [const Shadow(blurRadius: 4, color: Colors.black)],
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
