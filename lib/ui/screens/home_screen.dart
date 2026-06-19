import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stage_section.dart';
import '../widgets/quest_map.dart';
import '../widgets/retro_widgets.dart';
import '../screens/hero_creation_screen.dart';

import '../../services/ticker_service.dart';

import '../../providers/hero_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late TickerService _tickerService;

  @override
  void initState() {
    super.initState();
    _tickerService = TickerService(ref);
    _tickerService.start();
  }

  @override
  void dispose() {
    _tickerService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroes = ref.watch(heroProvider);
    final hero = heroes.isNotEmpty ? heroes.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: Stack(
        children: [
          // Main Game Map
          QuestMap(hero: hero),

          // Top Overlay (Resources & Stats)
          const Positioned(top: 0, left: 0, right: 0, child: StageSection()),

          // No Hero Overlay
          if (hero == null)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: RetroPanel(
                    backgroundColor: Colors.grey[900],
                    borderWidth: 3.0,
                    bevelWidth: 3.0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "YOUR JOURNEY BEGINS...",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.vt323(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 32),
                        RetroButton(
                          backgroundColor: Colors.amber[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HeroCreationScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "RECRUIT MERCENARY",
                            style: GoogleFonts.vt323(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
