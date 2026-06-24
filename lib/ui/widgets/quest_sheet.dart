import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/game_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/hero_provider.dart';
import '../../models/quest_model.dart';
import '../../models/hero_model.dart';
import '../../utils/game_logic.dart';
import '../../services/quest_service.dart';
import '../../utils/quest_logic.dart';

class QuestSheet extends ConsumerWidget {
  final HeroModel hero;
  final ScrollController? scrollController;

  const QuestSheet({super.key, required this.hero, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questLoad = ref.watch(questLoaderProvider);

    return questLoad.when(
      loading: () => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      ),
      error: (err, stack) => Container(
        height: 200,
        color: Colors.grey[900],
        child: Center(
          child: Text("Error: $err", style: const TextStyle(color: Colors.red)),
        ),
      ),
      data: (_) {
        final questService = ref.watch(questServiceProvider);
        final gameState = ref.watch(gameProvider);
        final heroes = ref.watch(heroProvider);
        // Get latest hero state
        final currentHero = heroes.firstWhere(
          (h) => h.id == hero.id,
          orElse: () => hero,
        );

        final mainQuests = questService.getMainQuests();

        // Ensure we have exactly 8 quests - if less, add placeholders
        final displayQuests = List<Quest?>.filled(8, null);
        for (int i = 0; i < mainQuests.length && i < 8; i++) {
          displayQuests[i] = mainQuests[i];
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Quest",
                    style: GoogleFonts.cinzel(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          FontAwesomeIcons.scroll,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _showSideQuests(
                            context,
                            ref,
                            questService,
                            gameState,
                            currentHero,
                          );
                        },
                        tooltip: "Side Quests",
                      ),
                      if (gameState.discoveredSideQuestIds.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${gameState.discoveredSideQuestIds.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final quest = displayQuests[index];
                    if (quest == null) {
                      return _buildLockedQuestCard("Coming Soon", true);
                    }

                    final isCompleted = gameState.completedQuestIds.contains(
                      quest.id,
                    );
                    final isLocked =
                        quest.requiredQuestId != null &&
                        !gameState.completedQuestIds.contains(
                          quest.requiredQuestId,
                        );

                    // Adjust Quest for display
                    final completionCount =
                        gameState.questCompletionCounts[quest.id] ?? 0;
                    final adjustedQuest = QuestLogic.getAdjustedQuest(
                      quest,
                      completionCount,
                    );

                    return _buildQuestCard(
                      context,
                      ref,
                      adjustedQuest,
                      isCompleted,
                      isLocked,
                      currentHero, // Pass latest hero
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestCard(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
    bool isCompleted,
    bool isLocked,
    HeroModel hero,
  ) {
    final successChance = GameLogic.calculateSuccessChance(hero, quest);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Quest Locked")));
        } else if (isCompleted && !quest.isReplayable) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Quest Completed")));
        } else {
          _showQuestDetails(context, ref, quest, hero);
        }
      },
      child: Card(
        color: isCompleted
            ? (quest.isReplayable ? Colors.green[800] : Colors.green[900])
            : (isLocked ? Colors.grey[800] : Colors.amber[900]),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted
                    ? (quest.isReplayable
                          ? FontAwesomeIcons.arrowRotateRight
                          : FontAwesomeIcons.circleCheck)
                    : (isLocked
                          ? FontAwesomeIcons.lock
                          : FontAwesomeIcons.skull),
                color: isLocked ? Colors.grey : Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                quest.title,
                style: GoogleFonts.cinzel(
                  color: isLocked ? Colors.grey : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                "Rec. Level ${quest.difficulty}",
                style: TextStyle(
                  color: isLocked ? Colors.grey[600] : Colors.grey[300],
                  fontSize: 12,
                ),
              ),
              if (!isLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Success: ${successChance.toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: successChance >= 80
                          ? Colors.green
                          : (successChance >= 50 ? Colors.orange : Colors.red),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isCompleted)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    FontAwesomeIcons.trophy,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedQuestCard(String text, bool isPlaceholder) {
    return Card(
      color: Colors.grey[850],
      elevation: 2,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.question, color: Colors.grey[700], size: 32),
            const SizedBox(height: 12),
            Text(
              text,
              style: GoogleFonts.cinzel(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSideQuests(
    BuildContext context,
    WidgetRef ref,
    QuestService service,
    GameState state,
    HeroModel hero,
  ) {
    final allSideQuests = service.getSideQuests();
    final visibleQuests = allSideQuests.where((q) {
      final isDiscovered = state.discoveredSideQuestIds.contains(q.id);
      final hasHints = (state.questHints[q.id] ?? 0) > 0;
      return isDiscovered || hasHints;
    }).toList();

    // Sort into three tiers: available → hint-locked → completed (non-replayable)
    visibleQuests.sort((a, b) {
      int tier(Quest q) {
        final isCompleted = state.completedQuestIds.contains(q.id);
        if (isCompleted && !q.isReplayable) return 2;
        final currentHints = state.questHints[q.id] ?? 0;
        if (q.requiredHints > 0 && currentHints < q.requiredHints) return 1;
        return 0;
      }

      final ta = tier(a);
      final tb = tier(b);
      if (ta != tb) return ta.compareTo(tb);
      return a.difficulty.compareTo(b.difficulty);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (sheetCtx) {
        final lastId = state.lastSideQuestId;
        final lastQuest = lastId != null ? service.getQuestById(lastId) : null;
        final canRedo = lastQuest != null &&
            state.discoveredSideQuestIds.contains(lastQuest.id);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Side Quests",
                    style: GoogleFonts.cinzel(fontSize: 20, color: Colors.white),
                  ),
                  if (canRedo)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        backgroundColor: Colors.amber.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                              color: Colors.amber, width: 1),
                        ),
                      ),
                      icon: const Icon(FontAwesomeIcons.arrowRotateLeft,
                          size: 12),
                      label: Text(
                        "Redo: ${lastQuest!.title}",
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        final completionCount =
                            state.questCompletionCounts[lastQuest.id] ?? 0;
                        final adjusted = QuestLogic.getAdjustedQuest(
                          lastQuest,
                          completionCount,
                        );
                        Navigator.pop(sheetCtx);
                        _startQuest(context, ref, adjusted, hero);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: visibleQuests.isEmpty
                  ? const Center(
                      child: Text(
                        "No side quests discovered yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: visibleQuests.length,
                      itemBuilder: (context, index) {
                        final quest = visibleQuests[index];
                        final isCompleted = state.completedQuestIds.contains(
                          quest.id,
                        );
                        final currentHints = state.questHints[quest.id] ?? 0;
                        final isLockedByHints =
                            quest.requiredHints > 0 &&
                            currentHints < quest.requiredHints;

                        // Adjust Quest
                        final completionCount =
                            state.questCompletionCounts[quest.id] ?? 0;
                        final adjustedQuest = QuestLogic.getAdjustedQuest(
                          quest,
                          completionCount,
                        );
                        final successChance = GameLogic.calculateSuccessChance(
                          hero,
                          adjustedQuest,
                        );

                        if (isCompleted && !quest.isReplayable) {
                          return ListTile(
                            title: Text(
                              quest.title,
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: const Text(
                              "Completed",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListTile(
                          isThreeLine: true,
                          title: Text(
                            quest.title,
                            style: GoogleFonts.cinzel(
                              color: isLockedByHints
                                  ? Colors.purpleAccent.withValues(alpha: 0.7)
                                  : Colors.white,
                            ),
                          ),
                          subtitle: isLockedByHints
                              ? Text(
                                  "Hints: $currentHints / ${quest.requiredHints} - Keep progressing to find more hints.",
                                  style: const TextStyle(
                                    color: Colors.purpleAccent,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Lvl ${adjustedQuest.difficulty} - ${adjustedQuest.durationSeconds}s${isCompleted ? ' (Replay)' : ''}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      "Success: ${successChance.toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        color: successChance >= 80
                                            ? Colors.green
                                            : (successChance >= 50
                                                  ? Colors.orange
                                                  : Colors.red),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                          trailing: isLockedByHints
                              ? const Icon(
                                  FontAwesomeIcons.lock,
                                  color: Colors.grey,
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _startQuest(
                                      context,
                                      ref,
                                      adjustedQuest,
                                      hero,
                                    );
                                  },
                                  child: const Text(
                                    "Start",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showQuestDetails(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
    HeroModel hero,
  ) {
    final gameState = ref.read(gameProvider);
    final isCompleted = gameState.completedQuestIds.contains(quest.id);
    final isReplay = isCompleted && quest.isReplayable;

    // Adjust Quest
    final completionCount = gameState.questCompletionCounts[quest.id] ?? 0;
    final adjustedQuest = QuestLogic.getAdjustedQuest(quest, completionCount);

    final goldReward = isReplay
        ? (adjustedQuest.repeatGoldReward ?? adjustedQuest.goldReward ~/ 2)
        : adjustedQuest.goldReward;
    final xpReward = isReplay
        ? (adjustedQuest.repeatXpReward ?? adjustedQuest.xpReward ~/ 2)
        : adjustedQuest.xpReward;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          quest.title,
          style: GoogleFonts.cinzel(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              adjustedQuest.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Recommended Level", "${adjustedQuest.difficulty}"),
            _buildInfoRow("Duration", "${adjustedQuest.durationSeconds}s"),
            _buildInfoRow("Gold Reward", "$goldReward"),
            _buildInfoRow("XP Reward", "$xpReward"),
            _buildInfoRow(
              "Success Chance",
              "${GameLogic.calculateSuccessChance(hero, adjustedQuest).toStringAsFixed(1)}%",
              color: GameLogic.calculateSuccessChance(hero, adjustedQuest) >= 80
                  ? Colors.green
                  : Colors.red,
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              "Estimates:",
              style: GoogleFonts.cinzel(color: Colors.white70),
            ),
            _buildInfoRow(
              "Est. HP Loss",
              "${GameLogic.calculateHealthLoss(hero, adjustedQuest)} HP",
              color: Colors.redAccent,
            ),
            _buildInfoRow(
              "Est. HP Loss",
              "${GameLogic.calculateHealthLoss(hero, adjustedQuest)} HP",
              color: Colors.redAccent,
            ),
            if (isReplay)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Replay Rewards Reduced",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close sheet too?
              // If we close the sheet, the user is back at home.
              // If we don't, the sheet stays open.
              // Usually starting a quest should close the selection UI.
              // But _startQuest closes the map/sheet.
              // Let's check _startQuest.
              _startQuest(context, ref, adjustedQuest, hero);
            },
            child: const Text("Embark", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _startQuest(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
    HeroModel hero,
  ) {
    // Cannot quest if downed/recovering or otherwise not idle.
    if (hero.hp <= 0 || hero.status != HeroStatus.idle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hero.status == HeroStatus.recovering
                ? "${hero.name} is still recovering."
                : "Hero is not ready to quest yet.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gameState = ref.read(gameProvider);
    final activeArtifacts = gameState.activeArtifacts;
    int duration = GameLogic.calculateQuestDuration(
      hero,
      quest,
      durationMultiplier: gameState.metaDurationMultiplier, // Haste (P3.1)
    );

    for (var artifact in activeArtifacts) {
      duration = artifact.modifyQuestDuration(duration);
    }

    // Track last side quest for the "Redo" button.
    if (!quest.isMainQuest) {
      ref.read(gameProvider.notifier).setLastSideQuestId(quest.id);
    }

    final updatedHero = hero.copyWith(
      status: HeroStatus.questing,
      questCompletesAt: DateTime.now().add(Duration(seconds: duration)),
      activeQuestId: quest.id,
      activeQuestActualDuration: duration,
    );

    ref.read(heroProvider.notifier).updateHero(updatedHero);
    // Navigator.pop(context); // This was closing the QuestSelection screen.
    // Since we are in a sheet, we might need to pop the sheet.
    // If called from _showQuestDetails, we popped the dialog.
    // We need to pop the sheet as well if we want to return to home.
    // But _startQuest is called after popping the dialog in _showQuestDetails.
    // So we just need one more pop?
    // Let's be safe and pop until we are at the root or close the sheet.
    // Actually, if we use showModalBottomSheet, it pushes a route.
    // So Navigator.pop(context) should close the sheet.
    // But wait, context passed to _startQuest might be from the Dialog if we didn't pop it yet?
    // In _showQuestDetails:
    // onPressed: () {
    //   Navigator.pop(context); // Pops Dialog
    //   Navigator.pop(context); // Pops Sheet? No, context is from builder.
    //   _startQuest(context, ref, quest);
    // }
    // If I add Navigator.pop(context) in _showQuestDetails before calling _startQuest,
    // then _startQuest doesn't need to pop anything?
    // Or _startQuest should pop the sheet.
    // The context passed to _startQuest is the context from build?
    // No, it's passed from the caller.
    // In _showQuestDetails, I'll pass the context of the dialog?
    // If I pop the dialog, that context is invalid?
    // No, but the route is gone.
    // I should probably handle navigation in the callback.

    // Let's simplify: _startQuest will NOT pop. The caller handles popping.
    // In _showQuestDetails:
    // Navigator.pop(context); // Close Dialog
    // Navigator.pop(context); // Close Sheet (we need the context of the sheet or parent)
    // But we are inside the sheet widget.
    // We can use `Navigator.of(context, rootNavigator: true).pop()`?

    // Let's just make _startQuest do nothing about navigation, and handle it in the button.
  }
}
