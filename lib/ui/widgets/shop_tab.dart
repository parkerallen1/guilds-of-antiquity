import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/game_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/hero_provider.dart';
import '../../models/item_model.dart';
import '../../models/quest_model.dart';
import '../../utils/loot_factory.dart';
import '../../services/quest_service.dart';
import 'retro_widgets.dart';

// Simple provider to hold shop items for the day
final shopItemsProvider = StateProvider<List<Item>>((ref) {
  // Generate 5 random items
  return List.generate(5, (index) => LootFactory.generate(1));
});

class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab> {
  @override
  void initState() {
    super.initState();
    // Check for quest refresh on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShopRefresh();
    });
  }

  void _checkShopRefresh() {
    final gameState = ref.read(gameProvider);
    final now = DateTime.now();
    final lastRefresh = gameState.lastShopRefresh;

    if (lastRefresh == null || now.difference(lastRefresh).inHours >= 3) {
      final questService = ref.read(questServiceProvider);
      // Ensure quests are loaded
      if (questService.getSideQuests().isNotEmpty) {
        final newQuests = questService.getRandomSideQuests(3);
        ref
            .read(gameProvider.notifier)
            .updateShopQuests(newQuests.map((q) => q.id).toList());

        // Also refresh items?
        ref.invalidate(shopItemsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopItems = ref.watch(shopItemsProvider);
    final gameState = ref.watch(gameProvider);
    final questService = ref.watch(questServiceProvider);

    final shopQuests = gameState.shopQuestIds
        .map((id) => questService.getQuestById(id))
        .whereType<Quest>()
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "THE MERCHANT",
                style: GoogleFonts.vt323(color: Colors.amber, fontSize: 26, letterSpacing: 1.5),
              ),
              Text(
                "REFRESHES EVERY 3H",
                style: GoogleFonts.pixelifySans(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (shopQuests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    "CONTRACTS",
                    style: GoogleFonts.vt323(color: Colors.white70, fontSize: 20, letterSpacing: 1.0),
                  ),
                ),
                ...shopQuests.map((quest) {
                  final isPurchased = gameState.discoveredSideQuestIds.contains(
                    quest.id,
                  );
                  return RetroPanel(
                    backgroundColor: Colors.grey[900],
                    borderWidth: 2,
                    bevelWidth: 2,
                    outlineColor: Colors.black,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(
                        FontAwesomeIcons.scroll,
                        color: Colors.amber,
                      ),
                      title: Text(
                        quest.title.toUpperCase(),
                        style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
                      ),
                      subtitle: Text(
                        "LVL ${quest.difficulty} SIDE QUEST",
                        style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
                      ),
                      trailing: isPurchased
                          ? const Icon(
                              FontAwesomeIcons.check,
                              color: Colors.green,
                            )
                          : RetroButton(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              onPressed: () => _buyQuest(quest, gameState.gold),
                              child: Text(
                                "${quest.difficulty * 10} G",
                                style: GoogleFonts.vt323(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                    ),
                  );
                }),
                const RetroDivider(color: Colors.black, height: 16, thickness: 2),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "CONSUMABLES",
                  style: GoogleFonts.vt323(color: Colors.white70, fontSize: 20, letterSpacing: 1.0),
                ),
              ),
              RetroPanel(
                backgroundColor: Colors.grey[900],
                borderWidth: 2,
                bevelWidth: 2,
                outlineColor: Colors.black,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.flask,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    "HEALTH POTION",
                    style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Text(
                    "RESTORES 50 HP.",
                    style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
                  ),
                  trailing: RetroButton(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: () => _buyPotion(context, ref, gameState),
                    child: Text(
                      "50 G",
                      style: GoogleFonts.vt323(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const RetroDivider(color: Colors.black, height: 16, thickness: 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "UPGRADES",
                  style: GoogleFonts.vt323(color: Colors.white70, fontSize: 20, letterSpacing: 1.0),
                ),
              ),
              RetroPanel(
                backgroundColor: Colors.grey[900],
                borderWidth: 2,
                bevelWidth: 2,
                outlineColor: Colors.black,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.sackDollar,
                    color: Colors.amber,
                  ),
                  title: Text(
                    "BAG UPGRADE (+5 SLOTS)",
                    style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Text(
                    "CURRENT LIMIT: ${gameState.inventoryLimit}",
                    style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
                  ),
                  trailing: RetroButton(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: () => _buyBagUpgrade(context, ref, gameState),
                    child: Text(
                      "${(gameState.inventoryLimit - 15) * 100} G",
                      style: GoogleFonts.vt323(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const RetroDivider(color: Colors.black, height: 16, thickness: 2),
              RetroPanel(
                backgroundColor: Colors.grey[900],
                borderWidth: 2,
                bevelWidth: 2,
                outlineColor: Colors.black,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.gem,
                    color: Colors.purpleAccent,
                  ),
                  title: Text(
                    "MYSTERIOUS SHARD",
                    style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Text(
                    "CONTAINS A HINT FOR A LEGENDARY QUEST.",
                    style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
                  ),
                  trailing: RetroButton(
                    backgroundColor: Colors.purple[600]!,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: () =>
                        _buyShard(context, ref, gameState, questService),
                    child: Text(
                      "500 G",
                      style: GoogleFonts.vt323(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const RetroDivider(color: Colors.black, height: 16, thickness: 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "EQUIPMENT",
                  style: GoogleFonts.vt323(color: Colors.white70, fontSize: 20, letterSpacing: 1.0),
                ),
              ),
              ...shopItems.map((item) {
                return RetroPanel(
                  backgroundColor: Colors.grey[900],
                  borderWidth: 2,
                  bevelWidth: 2,
                  outlineColor: Colors.black,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: RetroPanel(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(4),
                      backgroundColor: Colors.black54,
                      borderWidth: 1.5,
                      bevelWidth: 1.5,
                      outlineColor: Colors.black,
                      highlightColor: _getRarityColor(item.rarity).withValues(alpha: 0.3),
                      child: item.imagePath != null
                          ? Image.asset(
                              item.imagePath!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              _getIconForSlot(item.slot),
                              color: _getRarityColor(item.rarity),
                              size: 20,
                            ),
                    ),
                    title: Text(
                      item.name.toUpperCase(),
                      style: GoogleFonts.vt323(color: _getRarityColor(item.rarity), fontSize: 18),
                    ),
                    subtitle: Text(
                      "${item.rarity.name.toUpperCase()} - ${item.value} GOLD",
                      style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
                    ),
                    trailing: RetroButton(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onPressed: () {
                        _buyItem(context, ref, item, gameState.gold);
                      },
                      child: Text(
                        "BUY",
                        style: GoogleFonts.vt323(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        RetroPanel(
          padding: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF0D0D0D),
          borderWidth: 3,
          bevelWidth: 3,
          outlineColor: Colors.black,
          highlightColor: Colors.amber.withValues(alpha: 0.2),
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.coins, color: Colors.amber),
              const SizedBox(width: 12),
              Text(
                "${gameState.gold} GOLD",
                style: GoogleFonts.vt323(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              RetroButton(
                backgroundColor: Colors.grey[850]!,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderWidth: 1.5,
                bevelWidth: 1.5,
                onPressed: () {
                  // Force Refresh (Debug)
                  ref
                      .read(gameProvider.notifier)
                      .updateShopQuests(
                        [],
                      );
                  final questService = ref.read(questServiceProvider);
                  final newQuests = questService.getRandomSideQuests(3);
                  ref
                      .read(gameProvider.notifier)
                      .updateShopQuests(newQuests.map((q) => q.id).toList());
                  ref.invalidate(shopItemsProvider);
                },
                child: Text(
                  "REFRESH (DEBUG)",
                  style: GoogleFonts.vt323(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _buyQuest(Quest quest, int currentGold) {
    final cost = quest.difficulty * 10;
    if (currentGold >= cost) {
      ref.read(gameProvider.notifier).spendGold(cost);
      ref.read(gameProvider.notifier).discoverSideQuest(quest.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Contract signed: ${quest.title}")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not enough gold!")));
    }
  }

  void _buyItem(
    BuildContext context,
    WidgetRef ref,
    Item item,
    int currentGold,
  ) {
    if (currentGold >= item.value) {
      ref.read(gameProvider.notifier).spendGold(item.value);

      // Remove from shop
      final currentItems = ref.read(shopItemsProvider);
      ref.read(shopItemsProvider.notifier).state = [
        for (final i in currentItems)
          if (i != item) i,
      ];

      // Add to shared inventory
      ref.read(gameProvider.notifier).addItem(item);

      // Log it (optional, maybe show snackbar)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bought ${item.name}")));
    }
  }

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.rare:
        return Colors.blueAccent;
      case ItemRarity.epic:
        return Colors.purpleAccent;
      case ItemRarity.legendary:
        return Colors.amber;
      case ItemRarity.quest:
        return Colors.tealAccent;
    }
  }

  IconData _getIconForSlot(ItemSlot slot) {
    switch (slot) {
      case ItemSlot.mainHand:
        return FontAwesomeIcons.khanda;
      case ItemSlot.offHand:
        return FontAwesomeIcons.shieldHalved;
      case ItemSlot.armor:
        return FontAwesomeIcons.shirt;
      case ItemSlot.accessory:
        return FontAwesomeIcons.ring;
      case ItemSlot.trophy:
        return FontAwesomeIcons.trophy;
    }
  }

  void _buyBagUpgrade(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
  ) {
    // Cost scales with limit: (Limit - 15) * 100.
    // Base limit 20. Cost = (20-15)*100 = 500.
    // Next limit 25. Cost = (25-15)*100 = 1000.
    final cost = (gameState.inventoryLimit - 15) * 100;

    if (gameState.gold >= cost) {
      ref.read(gameProvider.notifier).spendGold(cost);
      ref.read(gameProvider.notifier).upgradeInventory(5);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Inventory Upgraded!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not enough gold!")));
    }
  }

  void _buyShard(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
    QuestService questService,
  ) {
    // 1. Get all quests that require hints
    final allQuests =
        questService.getSideQuests() + questService.getMainQuests();
    final legendaryQuests = allQuests
        .where((q) => q.requiredHints > 0)
        .toList();

    // 2. Filter for quests that still need hints, lowest difficulty first so a
    //    shard always advances the nearest legendary quest (P1.4). Previously a
    //    shard hit a RANDOM eligible quest, so progress on the one you wanted
    //    (e.g. dragon_lair) was taxed by hints wasted on others.
    final eligibleQuests =
        legendaryQuests.where((q) {
          final currentHints = gameState.questHints[q.id] ?? 0;
          return currentHints < q.requiredHints;
        }).toList()
          ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

    if (eligibleQuests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No more secrets to uncover.")),
      );
      return;
    }

    // 3. Call buyShard with eligible IDs (lowest-difficulty first).
    ref
        .read(gameProvider.notifier)
        .buyShard(eligibleQuests.map((q) => q.id).toList());
  }

  void _buyPotion(BuildContext context, WidgetRef ref, GameState gameState) {
    final heroes = ref.read(heroProvider);
    if (heroes.isEmpty) return;

    // Assume single hero for now
    final hero = heroes.first;

    if (hero.hp >= hero.maxHp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hero is already at full health!")),
      );
      return;
    }

    if (gameState.gold >= 50) {
      ref.read(gameProvider.notifier).spendGold(50);

      final newHp = (hero.hp + 50).clamp(0, hero.maxHp);
      ref.read(heroProvider.notifier).updateHero(hero.copyWith(hp: newHp));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Restored health to $newHp/${hero.maxHp}")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not enough gold!")));
    }
  }
}
