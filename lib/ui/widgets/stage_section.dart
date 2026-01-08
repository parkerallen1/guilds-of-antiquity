import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../providers/hero_provider.dart';

class StageSection extends ConsumerWidget {
  const StageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final heroes = ref.watch(heroProvider);

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

            // Debug Theme Cycle (Center)
            IconButton(
              icon: const Icon(Icons.color_lens, color: Colors.white24),
              onPressed: () {
                ref.read(gameProvider.notifier).debugCycleEra();
              },
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
