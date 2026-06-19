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
import '../screens/hall_screen.dart';
import '../screens/museum_screen.dart';
import 'tavern_tab.dart';
import 'shop_tab.dart';
import 'hero_detail_sheet.dart';
import 'quest_status_box.dart';

class QuestMap extends ConsumerWidget {
  final HeroModel? hero;

  const QuestMap({super.key, required this.hero});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questLoader = ref.watch(questLoaderProvider);

    return questLoader.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading quests: $err')),
      data: (_) {
        final questService = ref.watch(questServiceProvider);
        final gameState = ref.watch(gameProvider);
        final heroes = ref.watch(heroProvider);
        // Get latest hero state
        final currentHero = heroes.isEmpty
            ? null
            : (hero == null
                  ? heroes.first
                  : heroes.firstWhere(
                      (h) => h.id == hero!.id,
                      orElse: () => hero!,
                    ));

        final mainQuests = questService.getMainQuests();

        return Stack(
          children: [
            // Background Map Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/war_table.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1a1a1a)),
              ),
            ),

            // Quest Connections
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 120,
                bottom: MediaQuery.of(context).padding.bottom + 120,
                left: 30,
                right: 30,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      ...mainQuests.map((quest) {
                        if (quest.requiredQuestId == null) {
                          return const SizedBox.shrink();
                        }
                        final parent = questService.getQuestById(
                          quest.requiredQuestId!,
                        );
                        if (parent == null) return const SizedBox.shrink();

                        return CustomPaint(
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          painter: LinePainter(
                            start: Offset(
                              parent.mapX * constraints.maxWidth,
                              parent.mapY * constraints.maxHeight,
                            ),
                            end: Offset(
                              quest.mapX * constraints.maxWidth,
                              quest.mapY * constraints.maxHeight,
                            ),
                            color:
                                gameState.completedQuestIds.contains(parent.id)
                                ? Colors.amber.withValues(alpha: 0.6)
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        );
                      }),

                      // Quest Nodes (Boxes)
                      ...mainQuests.map((quest) {
                        final isCompleted = gameState.completedQuestIds
                            .contains(quest.id);
                        final isLocked =
                            quest.requiredQuestId != null &&
                            !gameState.completedQuestIds.contains(
                              quest.requiredQuestId,
                            );

                        // Box dimensions
                        const double boxWidth = 100;
                        const double boxHeight = 50;

                        return Positioned(
                          left:
                              quest.mapX * constraints.maxWidth -
                              (boxWidth / 2),
                          top:
                              quest.mapY * constraints.maxHeight -
                              (boxHeight / 2),
                          child: GestureDetector(
                            onTap: () {
                              if (isLocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Quest Locked")),
                                );
                              } else if (isCompleted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Quest Completed"),
                                  ),
                                );
                              } else {
                                if (currentHero != null) {
                                  _showQuestDetails(
                                    context,
                                    quest,
                                    currentHero.id,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("No Hero Selected"),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: boxWidth,
                              height: boxHeight,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green[900]
                                    : (isLocked
                                          ? Colors.grey[800]
                                          : Colors.amber[900]),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isLocked
                                      ? Colors.grey
                                      : Colors.amberAccent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isCompleted
                                            ? FontAwesomeIcons.check
                                            : (isLocked
                                                  ? FontAwesomeIcons.lock
                                                  : FontAwesomeIcons.skull),
                                        color: isCompleted
                                            ? Colors.white
                                            : (isLocked
                                                  ? Colors.grey[400]
                                                  : Colors.amber),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          quest.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cinzel(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // Main City Button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              child: _buildCityButton(context),
            ),

            // Side Quests Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 16,
              child: FloatingActionButton.extended(
                heroTag: 'side_quests',
                onPressed: () =>
                    _showSideQuests(context, questService, currentHero!.id),
                backgroundColor: Colors.amber,
                icon: const Icon(FontAwesomeIcons.scroll, color: Colors.black),
                label: Text(
                  "Side Quests",
                  style: GoogleFonts.cinzel(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Hero Button (Bottom Right)
            if (hero != null) ...[
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 100,
                right: 16,
                child: QuestStatusBox(hero: hero!),
              ),
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                right: 16,
                child: _buildHeroButton(context, hero!),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCityButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCityMenu(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              FontAwesomeIcons.fortAwesome,
              color: Colors.amber,
              size: 40,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "CAPITAL",
            style: GoogleFonts.cinzel(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [const Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButton(BuildContext context, HeroModel hero) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => HeroDetailSheet(hero: hero),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.amber),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(
                hero.imagePath ??
                    (hero.id.hashCode % 2 == 0
                        ? 'assets/images/heroes/male_warrior.png'
                        : 'assets/images/heroes/female_warrior.png'),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hero.name,
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Lvl ${hero.level}",
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
                const SizedBox(height: 4),
                // Mini HP Bar
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: hero.hp / hero.maxHp,
                    backgroundColor: Colors.red[900],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 2),
                // Mini XP Bar
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: hero.xp / (hero.level * 100),
                    backgroundColor: Colors.blue[900],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCityMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "The Capital City",
              style: GoogleFonts.cinzel(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildCityOption(
                  context,
                  "Tavern",
                  FontAwesomeIcons.beerMugEmpty,
                  Colors.brown,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: Text(
                            "The Tavern",
                            style: GoogleFonts.cinzel(),
                          ),
                          backgroundColor: Colors.brown[900],
                        ),
                        body: const TavernTab(),
                      ),
                    ),
                  ),
                ),
                _buildCityOption(
                  context,
                  "Shop",
                  FontAwesomeIcons.sackDollar,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: Text(
                            "Marketplace",
                            style: GoogleFonts.cinzel(),
                          ),
                          backgroundColor: Colors.green[900],
                        ),
                        body: const ShopTab(),
                      ),
                    ),
                  ),
                ),
                _buildCityOption(
                  context,
                  "Hall",
                  FontAwesomeIcons.dungeon,
                  Colors.blueGrey,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HallScreen()),
                  ),
                ),
                _buildCityOption(
                  context,
                  "Museum",
                  Icons.museum,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MuseumScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close menu
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSideQuests(
    BuildContext context,
    QuestService service,
    String heroId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final gameState = ref.watch(gameProvider);
          final heroes = ref.watch(heroProvider);
          final hero = heroes.firstWhere(
            (h) => h.id == heroId,
            orElse: () => heroes.first,
          );

          final sideQuests = gameState.discoveredSideQuestIds
              .map((id) => service.getQuestById(id))
              .whereType<Quest>()
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Side Quests",
                  style: GoogleFonts.cinzel(fontSize: 20, color: Colors.white),
                ),
              ),
              Expanded(
                child: sideQuests.isEmpty
                    ? const Center(
                        child: Text(
                          "No side quests discovered yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sideQuests.length,
                        itemBuilder: (context, index) {
                          final quest = sideQuests[index];
                          // Adjust Quest
                          final completionCount =
                              gameState.questCompletionCounts[quest.id] ?? 0;
                          final adjustedQuest = QuestLogic.getAdjustedQuest(
                            quest,
                            completionCount,
                          );
                          final successChance =
                              GameLogic.calculateSuccessChance(
                                hero,
                                adjustedQuest,
                              );

                          return ListTile(
                            isThreeLine: true,
                            title: Text(
                              quest.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Lvl ${adjustedQuest.difficulty} - ${adjustedQuest.durationSeconds}s",
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Close sheet
                                _startQuest(context, ref, adjustedQuest, hero);
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
      ),
    );
  }

  void _showQuestDetails(BuildContext context, Quest quest, String heroId) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final gameState = ref.watch(gameProvider);
          final heroes = ref.watch(heroProvider);
          final hero = heroes.firstWhere(
            (h) => h.id == heroId,
            orElse: () => heroes.first,
          );

          final completionCount =
              gameState.questCompletionCounts[quest.id] ?? 0;
          final adjustedQuest = QuestLogic.getAdjustedQuest(
            quest,
            completionCount,
          );

          return AlertDialog(
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
                  quest.description,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  "Recommended Level",
                  "${adjustedQuest.difficulty}",
                ),
                _buildInfoRow("Duration", "${adjustedQuest.durationSeconds}s"),
                _buildInfoRow("Gold Reward", "${adjustedQuest.goldReward}"),
                _buildInfoRow("XP Reward", "${adjustedQuest.xpReward}"),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  "Estimates:",
                  style: GoogleFonts.cinzel(color: Colors.white70),
                ),
                _buildInfoRow(
                  "Success Chance",
                  "${GameLogic.calculateSuccessChance(hero, adjustedQuest).toStringAsFixed(1)}%",
                  color:
                      GameLogic.calculateSuccessChance(hero, adjustedQuest) >=
                          80
                      ? Colors.green
                      : Colors.red,
                ),
                _buildInfoRow(
                  "Est. HP Loss",
                  "${GameLogic.calculateHealthLoss(hero, adjustedQuest)} HP",
                  color: Colors.redAccent,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  Navigator.pop(context);
                  _startQuest(context, ref, adjustedQuest, hero);
                },
                child: const Text(
                  "Embark",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
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
      durationMultiplier: 1.0,
    );

    for (var artifact in activeArtifacts) {
      duration = artifact.modifyQuestDuration(duration);
    }

    final updatedHero = hero.copyWith(
      status: HeroStatus.questing,
      questCompletesAt: DateTime.now().add(Duration(seconds: duration)),
      activeQuestId: quest.id,
    );

    ref.read(heroProvider.notifier).updateHero(updatedHero);
    // Navigator.pop(context); // Map is main screen now, no need to pop
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${hero.name} has embarked on ${quest.title}!")),
    );
  }
}

class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  LinePainter({required this.start, required this.end, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
