import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/game_provider.dart';
import '../../providers/quest_provider.dart';
import '../../utils/asset_utils.dart';

class TavernTab extends ConsumerStatefulWidget {
  const TavernTab({super.key});

  @override
  ConsumerState<TavernTab> createState() => _TavernTabState();
}

class _TavernTabState extends ConsumerState<TavernTab> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final now = DateTime.now();
    final nextTime = gameState.nextTavernQuestTime;

    // If nextTime is null, set it.
    if (nextTime == null) {
      // Schedule first one soon for testing, or 10-14 hours as requested.
      // For testing, let's say 10 seconds.
      // For production, use 10-14 hours.
      // I'll use a short duration for now to verify it works, or stick to spec?
      // User said "every 10-14 hours".
      // I'll implement the logic but maybe trigger it immediately if null for the first time?
      // "Every now and then... people have an exclamation mark".
      // Let's set it to Now so they see it immediately on first load.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleNextQuest(Duration.zero);
      });
    }

    final isQuestAvailable = nextTime != null && now.isAfter(nextTime);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/tavern_bg.png'), // Placeholder
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          // Patrons
          Positioned(
            left: 50,
            bottom: 100,
            child: _buildPatron(
              context,
              "Old Mercenary",
              'assets/images/npcs/old_mercenary.png',
              isQuestAvailable,
            ),
          ),
          Positioned(
            right: 60,
            bottom: 120,
            child: _buildPatron(
              context,
              "Mysterious Traveler",
              'assets/images/npcs/mysterious_traveler.png',
              false, // Only one quest at a time?
            ),
          ),
          Positioned(
            left: 150,
            bottom: 180,
            child: _buildPatron(
              context,
              "Bartender",
              'assets/images/npcs/bartender.png',
              false,
            ),
          ),

          // Title
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "The Rusty Tankard",
                style: GoogleFonts.cinzel(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatron(
    BuildContext context,
    String name,
    String baseImagePath,
    bool hasQuest,
  ) {
    return GestureDetector(
      onTap: () {
        if (hasQuest) {
          _showQuestDialog(context);
        } else {
          _showGossipDialog(context, name);
        }
      },
      child: Column(
        children: [
          if (hasQuest) AnimateExclamation(),
          FutureBuilder<String>(
            future: AssetUtils.getRandomVariation(context, baseImagePath),
            builder: (context, snapshot) {
              final imagePath = snapshot.data ?? baseImagePath;
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.brown[700]!, width: 2),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
                child: null,
              );
            },
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showGossipDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(name, style: const TextStyle(color: Colors.amber)),
        content: const Text(
          "\"Business is slow these days...\"",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Leave"),
          ),
        ],
      ),
    );
  }

  void _showQuestDialog(BuildContext context) {
    final questService = ref.read(questServiceProvider);
    final quests = questService.getRandomSideQuests(1);

    if (quests.isEmpty) {
      // Fallback if no quests
      _scheduleNextQuest(const Duration(hours: 1));
      return;
    }

    final quest = quests.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("A Rumor...", style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You hear whispers of ${quest.title}.",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              quest.description,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(
                  "${quest.durationSeconds}s",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "${quest.goldReward}",
                  style: const TextStyle(color: Colors.amber),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset timer without accepting? Maybe keep it available?
              // Let's say ignore means it's gone for now.
              _scheduleNextQuest(const Duration(hours: 10));
            },
            child: const Text("Ignore", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              ref.read(gameProvider.notifier).discoverSideQuest(quest.id);
              _scheduleNextQuest(const Duration(hours: 10)); // 10-14 hours
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Quest Discovered: ${quest.title}")),
              );
            },
            child: const Text(
              "Investigate",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleNextQuest(Duration delay) {
    final random = Random();

    // If delay is zero (initial), use it.
    if (delay == Duration.zero) {
      final nextTime = DateTime.now();
      ref.read(gameProvider.notifier).setNextTavernQuestTime(nextTime);
      return;
    }

    // Calculate dynamic delay based on progress
    final gameState = ref.read(gameProvider);
    final completedMainQuests =
        gameState.completedQuestIds.length; // Approximate count of main quests
    // Actually completedQuestIds includes side quests too.
    // We should filter or just use total count as a proxy for progress.
    // Let's use total count.

    // Base: 10-14 hours
    // Reduction: 30 mins per completed quest
    int baseMinutes = 10 * 60;
    int reduction = completedMainQuests * 30;
    int targetMinutes = baseMinutes - reduction;

    // Minimum 1 hour (60 mins)
    if (targetMinutes < 60) targetMinutes = 60;

    // Add variance (0-4 hours)
    int variance = random.nextInt(4 * 60);

    // If we want it "more often", maybe we should reduce the variance too?
    // Let's just stick to the reduction logic.

    final finalDelay = Duration(minutes: targetMinutes + variance);

    final nextTime = DateTime.now().add(finalDelay);
    ref.read(gameProvider.notifier).setNextTavernQuestTime(nextTime);
  }
}

class AnimateExclamation extends StatefulWidget {
  const AnimateExclamation({super.key});

  @override
  State<AnimateExclamation> createState() => _AnimateExclamationState();
}

class _AnimateExclamationState extends State<AnimateExclamation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: Icon(
          FontAwesomeIcons.exclamation,
          color: Colors.redAccent,
          size: 32,
        ),
      ),
    );
  }
}
