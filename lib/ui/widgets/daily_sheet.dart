import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/daily_objective.dart';
import '../../providers/daily_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/quest_provider.dart';
import 'retro_widgets.dart';

/// Bottom sheet for the short-term goal layer: daily login reward, three
/// rotating objectives, and a couple of free bounties.
void showDailySheet(BuildContext context, WidgetRef ref) {
  // Roll over to today before showing (captures baselines, grants the login).
  ref.read(dailyProvider.notifier).refresh();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const DailySheet(),
  );
}

class DailySheet extends ConsumerWidget {
  const DailySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch game + heroes so progress bars update live as the player plays.
    ref.watch(gameProvider);
    ref.watch(heroProvider);
    final daily = ref.watch(dailyProvider);
    final notifier = ref.read(dailyProvider.notifier);
    final questService = ref.watch(questServiceProvider);

    return RetroPanel(
      backgroundColor: const Color(0xFF1A1A1A),
      borderWidth: 3,
      bevelWidth: 3,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "DAILY",
                style: GoogleFonts.vt323(
                  color: Colors.amber,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
            ),
            const RetroDivider(color: Colors.black, height: 20, thickness: 2),

            // --- Login reward ---
            _LoginRewardPanel(
              day: ((daily.loginCount - 1) % kLoginRewards.length) + 1,
              reward: notifier.loginReward,
              claimed: daily.loginClaimedToday,
              onClaim: () => notifier.claimLoginReward(),
            ),
            const SizedBox(height: 16),

            _sectionLabel("OBJECTIVES"),
            const SizedBox(height: 8),
            for (int i = 0; i < daily.objectives.length; i++)
              _ObjectiveTile(
                objective: daily.objectives[i],
                progress: notifier.progressOf(i),
                claimed: daily.claimed[i],
                canClaim: notifier.canClaim(i),
                onClaim: () => notifier.claimObjective(i),
              ),

            if (daily.bountyQuestIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionLabel("FREE BOUNTIES"),
              const SizedBox(height: 8),
              for (final id in daily.bountyQuestIds)
                Builder(
                  builder: (context) {
                    final quest = questService.getQuestById(id);
                    if (quest == null) return const SizedBox.shrink();
                    final accepted = ref
                        .watch(gameProvider)
                        .discoveredSideQuestIds
                        .contains(id);
                    return _BountyTile(
                      title: quest.title,
                      difficulty: quest.difficulty,
                      accepted: accepted,
                      onAccept: () => notifier.acceptBounty(id),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.vt323(
          color: Colors.white70,
          fontSize: 20,
          letterSpacing: 1.5,
        ),
      );
}

class _LoginRewardPanel extends StatelessWidget {
  final int day;
  final int reward;
  final bool claimed;
  final VoidCallback onClaim;
  const _LoginRewardPanel({
    required this.day,
    required this.reward,
    required this.claimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      backgroundColor: const Color(0xFF0D0D0D),
      borderWidth: 2,
      bevelWidth: 2,
      highlightColor: Colors.amber.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(FontAwesomeIcons.calendarCheck, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DAILY LOGIN — DAY $day",
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
                ),
                Text(
                  "+$reward gold",
                  style: GoogleFonts.pixelifySans(
                    color: Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          claimed
              ? const Icon(FontAwesomeIcons.check, color: Colors.green)
              : RetroButton(
                  backgroundColor: Colors.amber,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  onPressed: onClaim,
                  child: Text(
                    "CLAIM",
                    style: GoogleFonts.vt323(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  final DailyObjective objective;
  final int progress;
  final bool claimed;
  final bool canClaim;
  final VoidCallback onClaim;
  const _ObjectiveTile({
    required this.objective,
    required this.progress,
    required this.claimed,
    required this.canClaim,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      backgroundColor: Colors.grey[900],
      borderWidth: 2,
      bevelWidth: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective.title.toUpperCase(),
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 6),
                RetroProgressBar(
                  value: objective.target == 0
                      ? 0
                      : progress / objective.target,
                  progressColor: claimed ? Colors.green : Colors.amber,
                  height: 12,
                ),
                const SizedBox(height: 4),
                Text(
                  "$progress / ${objective.target}   •   +${objective.rewardGold} G",
                  style: GoogleFonts.pixelifySans(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (claimed)
            const Icon(FontAwesomeIcons.check, color: Colors.green)
          else
            RetroButton(
              backgroundColor: canClaim ? Colors.amber : Colors.grey[800]!,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: canClaim ? onClaim : () {},
              child: Text(
                "CLAIM",
                style: GoogleFonts.vt323(
                  color: canClaim ? Colors.black : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BountyTile extends StatelessWidget {
  final String title;
  final int difficulty;
  final bool accepted;
  final VoidCallback onAccept;
  const _BountyTile({
    required this.title,
    required this.difficulty,
    required this.accepted,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      backgroundColor: Colors.grey[900],
      borderWidth: 2,
      bevelWidth: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(FontAwesomeIcons.crosshairs, color: Colors.redAccent),
        title: Text(
          title.toUpperCase(),
          style: GoogleFonts.vt323(color: Colors.white, fontSize: 17),
        ),
        subtitle: Text(
          "LVL $difficulty BOUNTY",
          style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
        ),
        trailing: accepted
            ? const Icon(FontAwesomeIcons.check, color: Colors.green)
            : RetroButton(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: onAccept,
                child: Text(
                  "ACCEPT",
                  style: GoogleFonts.vt323(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }
}
