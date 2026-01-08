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
        ref.refresh(shopItemsProvider);
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
                style: GoogleFonts.cinzel(color: Colors.amber, fontSize: 20),
              ),
              Text(
                "Refreshes every 3h",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                    style: GoogleFonts.cinzel(color: Colors.white70),
                  ),
                ),
                ...shopQuests.map((quest) {
                  final isPurchased = gameState.discoveredSideQuestIds.contains(
                    quest.id,
                  );
                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        FontAwesomeIcons.scroll,
                        color: Colors.amber,
                      ),
                      title: Text(
                        quest.title,
                        style: GoogleFonts.cinzel(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Lvl ${quest.difficulty} Side Quest",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: isPurchased
                          ? const Icon(
                              FontAwesomeIcons.check,
                              color: Colors.green,
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                              ),
                              onPressed: () => _buyQuest(quest, gameState.gold),
                              child: Text(
                                "${quest.difficulty * 10} G",
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                    ),
                  );
                }),
                const Divider(color: Colors.grey),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "CONSUMABLES",
                  style: GoogleFonts.cinzel(color: Colors.white70),
                ),
              ),
              Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.flask,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    "Health Potion",
                    style: GoogleFonts.cinzel(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Restores 50 HP.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () => _buyPotion(context, ref, gameState),
                    child: const Text(
                      "50 G",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "UPGRADES",
                  style: GoogleFonts.cinzel(color: Colors.white70),
                ),
              ),
              Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.sackDollar,
                    color: Colors.amber,
                  ),
                  title: Text(
                    "Bag Upgrade (+5 Slots)",
                    style: GoogleFonts.cinzel(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Current Limit: ${gameState.inventoryLimit}",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: () => _buyBagUpgrade(context, ref, gameState),
                    child: Text(
                      "${(gameState.inventoryLimit - 15) * 100} G",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.gem,
                    color: Colors.purpleAccent,
                  ),
                  title: Text(
                    "Mysterious Shard",
                    style: GoogleFonts.cinzel(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Contains a hint for a Legendary Quest.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    onPressed: () =>
                        _buyShard(context, ref, gameState, questService),
                    child: const Text(
                      "500 G",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "EQUIPMENT",
                  style: GoogleFonts.cinzel(color: Colors.white70),
                ),
              ),
              ...shopItems.map((item) {
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _getRarityColor(item.rarity)),
                        borderRadius: BorderRadius.circular(4),
                        image: item.imagePath != null
                            ? DecorationImage(
                                image: AssetImage(item.imagePath!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.imagePath == null
                          ? Icon(
                              _getIconForSlot(item.slot),
                              color: _getRarityColor(item.rarity),
                            )
                          : null,
                    ),
                    title: Text(
                      item.name,
                      style: GoogleFonts.cinzel(color: Colors.white),
                    ),
                    subtitle: Text(
                      "${item.rarity.name.toUpperCase()} - ${item.value} Gold",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      onPressed: () {
                        _buyItem(context, ref, item, gameState.gold);
                      },
                      child: const Text(
                        "BUY",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black54,
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.coins, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                "${gameState.gold} Gold",
                style: GoogleFonts.cinzel(color: Colors.white, fontSize: 18),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Force Refresh (Debug)
                  ref
                      .read(gameProvider.notifier)
                      .updateShopQuests(
                        [],
                      ); // Clear to force refresh logic next check?
                  // Or just call check
                  final questService = ref.read(questServiceProvider);
                  final newQuests = questService.getRandomSideQuests(3);
                  ref
                      .read(gameProvider.notifier)
                      .updateShopQuests(newQuests.map((q) => q.id).toList());
                  ref.refresh(shopItemsProvider);
                },
                child: const Text("Refresh Stock (Debug)"),
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

    // 2. Filter for quests that still need hints
    final eligibleQuests = legendaryQuests.where((q) {
      final currentHints = gameState.questHints[q.id] ?? 0;
      return currentHints < q.requiredHints;
    }).toList();

    if (eligibleQuests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No more secrets to uncover.")),
      );
      return;
    }

    // 3. Call buyShard with eligible IDs
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
