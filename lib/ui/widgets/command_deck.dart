import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/hero_provider.dart';
import '../../models/hero_model.dart';
import 'hero_detail_sheet.dart';
import 'shop_tab.dart';
import '../screens/hall_screen.dart';
import 'quest_sheet.dart';
import '../screens/hero_creation_screen.dart';
import '../dialogs/end_game_dialog.dart';

import '../../providers/game_provider.dart';

import 'tavern_tab.dart';

class CommandDeck extends ConsumerStatefulWidget {
  const CommandDeck({super.key});

  @override
  ConsumerState<CommandDeck> createState() => _CommandDeckState();
}

class _CommandDeckState extends ConsumerState<CommandDeck>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameProvider, (previous, next) {
      if (next.completedQuestIds.contains('siege_capital') &&
          !(previous?.completedQuestIds.contains('siege_capital') ?? false)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const EndGameDialog(),
        );
      }
    });

    return Container(
      color: const Color(0xFF222222),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(FontAwesomeIcons.userShield), text: "HERO"),
                Tab(icon: Icon(FontAwesomeIcons.beerMugEmpty), text: "TAVERN"),
                Tab(icon: Icon(FontAwesomeIcons.sackDollar), text: "SHOP"),
                Tab(icon: Icon(FontAwesomeIcons.dungeon), text: "THE HALL"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  HeroTab(),
                  TavernTab(),
                  ShopTab(),
                  HallScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroTab extends ConsumerWidget {
  const HeroTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroes = ref.watch(heroProvider);

    if (heroes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "No hero selected.",
              style: GoogleFonts.lato(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HeroCreationScreen(),
                  ),
                );
              },
              child: const Text(
                "Create Hero",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    // Single Hero Mode
    final hero = heroes.first;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Card
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => HeroDetailSheet(hero: hero),
                          );
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(
                            hero.id.hashCode % 2 == 0
                                ? 'assets/images/heroes/male_warrior.png'
                                : 'assets/images/heroes/female_warrior.png',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.mapLocationDot,
                            color: Colors.amber,
                          ),
                          onPressed: () => _showQuestSheet(context, hero),
                          tooltip: "Quest Map",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hero.name,
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    "Lvl ${hero.level} ${hero.classType}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // HP Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "HP: ${hero.hp}/${hero.maxHp}",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      LinearProgressIndicator(
                        value: hero.hp / hero.maxHp,
                        backgroundColor: Colors.red[900],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // XP Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "XP: ${hero.xp}/${hero.level * 100}",
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                      LinearProgressIndicator(
                        value: hero.xp / (hero.level * 100),
                        backgroundColor: Colors.blue[900],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Action Button
          _buildActionButton(context, ref, hero),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    HeroModel hero,
  ) {
    if (hero.status == HeroStatus.questing) {
      final remaining = hero.questCompletesAt!.difference(DateTime.now());
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 24),
        ),
        onPressed: null,
        child: Text(
          "Questing... ${remaining.inSeconds}s",
          style: const TextStyle(color: Colors.amber, fontSize: 18),
        ),
      );
    } else if (hero.status == HeroStatus.recovering ||
        hero.status == HeroStatus.dead) {
      final reviveCost = 50 * hero.level;
      final gold = ref.watch(gameProvider).gold;
      final canAfford = gold >= reviveCost;
      final pct = (hero.hp / hero.maxHp * 100).clamp(0, 100).toInt();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Recovering... $pct%",
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? Colors.red[800] : Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: canAfford
                  ? () {
                      ref.read(gameProvider.notifier).spendGold(reviveCost);
                      ref
                          .read(heroProvider.notifier)
                          .updateHero(
                            hero.copyWith(
                              hp: hero.maxHp,
                              status: HeroStatus.idle,
                            ),
                          );
                    }
                  : null,
              child: Text(
                "Revive ($reviveCost g)",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          padding: const EdgeInsets.symmetric(vertical: 24),
        ),
        onPressed: () => _showQuestSheet(context, hero),
        child: Text(
          "ADVENTURE",
          style: GoogleFonts.cinzel(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _showQuestSheet(BuildContext context, HeroModel hero) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) =>
            QuestSheet(hero: hero, scrollController: controller),
      ),
    );
  }
}
