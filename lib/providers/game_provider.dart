import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../models/item_model.dart';
import '../models/business_model.dart';
import '../models/artifact.dart';
import '../models/museum_state.dart';
import '../models/log_entry_model.dart';
import '../data/museum_sets.dart';

import '../services/feedback_service.dart';
import '../services/audio_service.dart';
import '../providers/log_provider.dart';
import '../utils/loot_factory.dart';
import '../utils/quest_factory.dart';
import '../models/meta_upgrade.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final feedback = ref.read(feedbackServiceProvider);
  final audio = ref.read(audioServiceProvider);
  final log = ref.read(logProvider.notifier);
  return GameNotifier(feedback, audio, log);
});

// ... (imports)

class GameState {
  final int gold;
  final DateTime lastSaveTime;
  final List<Item> inventory;

  // Phase 3: Empire & Prestige
  final int currentEraIndex;
  final List<Item> vaultItems;
  final int ancientCoins;
  final Business? activeBusiness;
  final int vaultLevel;

  // Phase 4: Artifacts
  final List<String> activeArtifactIds;

  // Quest State
  final List<String> completedQuestIds;
  final List<String> discoveredSideQuestIds;
  final List<String> shopQuestIds;
  final DateTime? lastShopRefresh;
  final DateTime? nextTavernQuestTime;
  final int inventoryLimit;
  final Map<String, int> questHints;
  final Map<String, int> questCompletionCounts;

  // Lifetime totals for the daily-objective layer. Monotonic — they only ever
  // increase, so day-start baselines can measure "today's" progress.
  final int lifetimeGoldEarned;
  final int lifetimeItemsFound;

  // Ancient-Coin meta tree: upgrade enum index -> purchased level. Permanent
  // (survives prestige).
  final Map<int, int> metaUpgradeLevels;

  GameState({
    required this.gold,
    required this.lastSaveTime,
    required this.inventory,
    required this.currentEraIndex,
    required this.vaultItems,
    required this.ancientCoins,
    this.activeBusiness,
    this.vaultLevel = 1,
    required this.activeArtifactIds,
    required this.completedQuestIds,
    required this.discoveredSideQuestIds,
    required this.shopQuestIds,
    this.lastShopRefresh,
    this.nextTavernQuestTime,
    this.inventoryLimit = 20,
    required this.questHints,
    required this.questCompletionCounts,
    this.lifetimeGoldEarned = 0,
    this.lifetimeItemsFound = 0,
    this.metaUpgradeLevels = const {},
  });

  int metaLevel(MetaUpgrade u) => metaUpgradeLevels[u.index] ?? 0;

  double get metaGoldMultiplier =>
      1.0 + MetaUpgradeCatalog.of(MetaUpgrade.greed).valueAt(metaLevel(MetaUpgrade.greed));
  double get metaXpMultiplier =>
      1.0 + MetaUpgradeCatalog.of(MetaUpgrade.scholar).valueAt(metaLevel(MetaUpgrade.scholar));
  double get metaDurationMultiplier =>
      1.0 + MetaUpgradeCatalog.of(MetaUpgrade.haste).valueAt(metaLevel(MetaUpgrade.haste));
  double get metaHealMultiplier =>
      1.0 + MetaUpgradeCatalog.of(MetaUpgrade.vigor).valueAt(metaLevel(MetaUpgrade.vigor));
  double get metaDropBonus =>
      MetaUpgradeCatalog.of(MetaUpgrade.fortune).valueAt(metaLevel(MetaUpgrade.fortune));
  double get metaCoinMultiplier =>
      1.0 + MetaUpgradeCatalog.of(MetaUpgrade.legacy).valueAt(metaLevel(MetaUpgrade.legacy));

  // Helper to get vault capacity
  int get vaultCapacity => vaultLevel;

  List<Artifact> get activeArtifacts {
    return activeArtifactIds
        .map((id) {
          switch (id) {
            case 'greed_coin':
              return GreedCoin();
            case 'chrono_dial':
              return ChronoDial();
            case 'phoenix_feather':
              return PhoenixFeather();
            default:
              return null;
          }
        })
        .whereType<Artifact>()
        .toList();
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final FeedbackService _feedback;
  final AudioService _audio;
  final LogNotifier _log;

  GameNotifier(this._feedback, this._audio, this._log) : super(_loadState()) {
    _ensureDefaultQuests();
  }

  void _ensureDefaultQuests() {
    final defaultQuests = ['daily_patrol', 'dungeon_delve', 'monster_hunt'];
    for (final id in defaultQuests) {
      if (!state.discoveredSideQuestIds.contains(id)) {
        discoverSideQuest(id);
      }
    }
  }

  static GameState _loadState() {
    final gold = HiveService.settingsBox.get('gold', defaultValue: 100);
    final lastSaveTimeStr = HiveService.settingsBox.get('lastSaveTime');
    final lastSaveTime = lastSaveTimeStr != null
        ? DateTime.parse(lastSaveTimeStr)
        : DateTime.now();
    final inventory = HiveService.inventoryBox.values.toList();

    final currentEraIndex = HiveService.settingsBox.get(
      'currentEraIndex',
      defaultValue: 0,
    );
    final ancientCoins = HiveService.settingsBox.get(
      'ancientCoins',
      defaultValue: 0,
    );
    final vaultItems = HiveService.vaultBox.values.toList();

    // Load Business
    final businessTypeIndex = HiveService.settingsBox.get('businessType');
    final businessAmountLevel = HiveService.settingsBox.get(
      'businessAmountLevel',
      defaultValue: 1,
    );
    final businessQualityLevel = HiveService.settingsBox.get(
      'businessQualityLevel', // Changed from speedLevel
      defaultValue: 1,
    );
    final businessLastCollectedStr = HiveService.settingsBox.get(
      'businessLastCollected',
    );
    final businessLastCollected = businessLastCollectedStr != null
        ? DateTime.parse(businessLastCollectedStr)
        : null;

    final productionFinishTimeStr = HiveService.settingsBox.get(
      'productionFinishTime',
    );
    final productionFinishTime = productionFinishTimeStr != null
        ? DateTime.parse(productionFinishTimeStr)
        : null;

    final selectedDurationMinutes = HiveService.settingsBox.get(
      'selectedDurationMinutes',
    );

    Business? activeBusiness;
    if (businessTypeIndex != null) {
      activeBusiness = Business(
        type: BusinessType.values[businessTypeIndex],
        amountLevel: businessAmountLevel,
        qualityLevel: businessQualityLevel,
        lastCollected: businessLastCollected,
        productionFinishTime: productionFinishTime,
        selectedDurationMinutes: selectedDurationMinutes,
      );
    }

    final vaultLevel = HiveService.settingsBox.get(
      'vaultLevel',
      defaultValue: 1,
    );

    final activeArtifactIds =
        (HiveService.settingsBox.get('activeArtifactIds', defaultValue: [])
                as List)
            .cast<String>();

    final inventoryLimit = HiveService.settingsBox.get(
      'inventoryLimit',
      defaultValue: 20,
    );

    final questHints =
        (HiveService.settingsBox.get('questHints', defaultValue: {}) as Map)
            .cast<String, int>();

    final questCompletionCounts =
        (HiveService.settingsBox.get('questCompletionCounts', defaultValue: {})
                as Map)
            .cast<String, int>();

    return GameState(
      gold: gold,
      lastSaveTime: lastSaveTime,
      inventory: inventory,
      currentEraIndex: currentEraIndex,
      vaultItems: vaultItems,
      ancientCoins: ancientCoins,
      activeBusiness: activeBusiness,
      vaultLevel: vaultLevel,
      activeArtifactIds: activeArtifactIds,
      completedQuestIds:
          (HiveService.settingsBox.get('completedQuestIds', defaultValue: [])
                  as List)
              .cast<String>(),
      discoveredSideQuestIds:
          (HiveService.settingsBox.get(
                    'discoveredSideQuestIds',
                    defaultValue: [],
                  )
                  as List)
              .cast<String>(),
      shopQuestIds:
          (HiveService.settingsBox.get('shopQuestIds', defaultValue: [])
                  as List)
              .cast<String>(),
      lastShopRefresh: HiveService.settingsBox.get('lastShopRefresh') != null
          ? DateTime.parse(HiveService.settingsBox.get('lastShopRefresh'))
          : null,
      nextTavernQuestTime:
          HiveService.settingsBox.get('nextTavernQuestTime') != null
          ? DateTime.parse(HiveService.settingsBox.get('nextTavernQuestTime'))
          : null,
      inventoryLimit: inventoryLimit,
      questHints: questHints,
      questCompletionCounts: questCompletionCounts,
      lifetimeGoldEarned: HiveService.settingsBox.get(
        'lifetimeGoldEarned',
        defaultValue: 0,
      ),
      lifetimeItemsFound: HiveService.settingsBox.get(
        'lifetimeItemsFound',
        defaultValue: 0,
      ),
      metaUpgradeLevels:
          (HiveService.settingsBox.get('metaUpgradeLevels', defaultValue: {})
                  as Map)
              .map((k, v) => MapEntry(int.parse(k.toString()), v as int)),
    );
  }

  void addGold(int amount, {bool showFeedback = true}) {
    // Phase 4: Artifact Hook
    double finalAmount = amount.toDouble();
    for (var artifact in state.activeArtifacts) {
      finalAmount = artifact.modifyGoldGain(finalAmount);
    }
    // P3.1: the Greed meta upgrade boosts all positive gold gains.
    if (amount > 0) finalAmount *= state.metaGoldMultiplier;

    final int earned = finalAmount.toInt();
    final newGold = state.gold + earned;
    final newLifetimeGold =
        state.lifetimeGoldEarned + (earned > 0 ? earned : 0);
    HiveService.settingsBox.put('gold', newGold);
    HiveService.settingsBox.put('lifetimeGoldEarned', newLifetimeGold);
    state = _copyWith(gold: newGold, lifetimeGoldEarned: newLifetimeGold);

    // Feedback
    if (amount > 0 && showFeedback) {
      _audio.playGoldSound();
      _feedback.showFloatingText(
        '+${finalAmount.toInt()} Gold',
        FeedbackType.gold,
      );
    }
  }

  void spendGold(int amount) {
    if (state.gold >= amount) {
      final newGold = state.gold - amount;
      HiveService.settingsBox.put('gold', newGold);
      state = _copyWith(gold: newGold);
    }
  }

  void addItem(Item item) {
    if (state.inventory.length >= state.inventoryLimit) {
      _feedback.showFloatingText("Inventory Full!", FeedbackType.error);
      return;
    }
    HiveService.inventoryBox.add(item);
    final newLifetimeItems = state.lifetimeItemsFound + 1;
    HiveService.settingsBox.put('lifetimeItemsFound', newLifetimeItems);
    state = _copyWith(
      inventory: [...state.inventory, item],
      lifetimeItemsFound: newLifetimeItems,
    );

    // Phase 4: Museum Update
    unlockMuseumItem(item.id);
  }

  void unlockMuseumItem(String itemId) {
    final box = HiveService.museumBox;
    // We need to import MuseumState or use dynamic if not imported (but we imported HiveService which has the box)
    // Actually HiveService.museumBox is Box<MuseumState>, so we need the type.
    // I need to import museum_state.dart in game_provider.dart if not already there.
    // Wait, I didn't import it in game_provider.dart yet.
    // I'll assume I'll add the import or use dynamic for now, but better to add import.
    // Let's add the import in a separate step or just use dynamic for now to avoid import mess again?
    // No, I should add the import.
    // But wait, I can just use dynamic for now to avoid import errors if I don't want to add import at top.
    // But I should add import.
    // Actually, I already checked game_provider.dart and it HAS `import '../models/museum_state.dart';` at line 6.
    // So I can just use MuseumState.

    final museumState =
        box.get('state') ??
        MuseumState(unlockedItemIds: [], unlockedEndings: []);

    if (!museumState.unlockedItemIds.contains(itemId)) {
      final newIds = [...museumState.unlockedItemIds, itemId];
      final newState = MuseumState(
        unlockedItemIds: newIds,
        unlockedEndings: museumState.unlockedEndings,
      );
      box.put('state', newState);

      // Feedback
      _feedback.showFloatingText(
        "Museum Collection Updated!",
        FeedbackType.info,
      );

      // Museum-set completion grants the set's Artifact (P3.2/P3.3). This is
      // driven by the fresh unlock, so it fires exactly once per set — even
      // the consumable Phoenix Feather won't re-grant later.
      final set = MuseumSets.setContaining(itemId);
      if (set != null &&
          set.isComplete(newIds) &&
          !state.activeArtifactIds.contains(set.artifactId)) {
        addArtifact(set.artifactId);
        _log.addLog(
          "${set.title} collection complete! Earned the ${set.artifactName}.",
          LogType.loot,
        );
        _feedback.showFloatingText(
          "ARTIFACT EARNED: ${set.artifactName}!",
          FeedbackType.success,
        );
        _audio.playLegendaryDrop();
      }
    }
  }

  void removeItem(Item item) {
    final key = HiveService.inventoryBox.keys.firstWhere(
      (k) => HiveService.inventoryBox.get(k)?.id == item.id,
      orElse: () => null,
    );

    if (key != null) {
      HiveService.inventoryBox.delete(key);
    }

    state = _copyWith(
      inventory: state.inventory.where((i) => i.id != item.id).toList(),
    );
  }

  void sellItem(Item item) {
    // Basic sell price logic: 10 gold + rarity bonus
    int sellValue = 10 + (item.rarity.index * 10);
    addGold(sellValue);
    removeItem(item);
    _feedback.showFloatingText("Sold for $sellValue Gold", FeedbackType.gold);
  }

  void upgradeInventory(int slots) {
    final newLimit = state.inventoryLimit + slots;
    HiveService.settingsBox.put('inventoryLimit', newLimit);
    state = _copyWith(inventoryLimit: newLimit);
    _feedback.showFloatingText("Bag Upgraded!", FeedbackType.success);
  }

  void updateLastSaveTime() {
    final now = DateTime.now();
    HiveService.settingsBox.put('lastSaveTime', now.toIso8601String());
    state = _copyWith(lastSaveTime: now);
  }

  // --- Phase 3 Methods ---

  void setBusiness(Business business) {
    HiveService.settingsBox.put('businessType', business.type.index);
    HiveService.settingsBox.put('businessAmountLevel', business.amountLevel);
    HiveService.settingsBox.put('businessQualityLevel', business.qualityLevel);
    if (business.lastCollected != null) {
      HiveService.settingsBox.put(
        'businessLastCollected',
        business.lastCollected!.toIso8601String(),
      );
    } else {
      HiveService.settingsBox.delete('businessLastCollected');
    }
    if (business.productionFinishTime != null) {
      HiveService.settingsBox.put(
        'productionFinishTime',
        business.productionFinishTime!.toIso8601String(),
      );
    } else {
      HiveService.settingsBox.delete('productionFinishTime');
    }
    if (business.selectedDurationMinutes != null) {
      HiveService.settingsBox.put(
        'selectedDurationMinutes',
        business.selectedDurationMinutes,
      );
    } else {
      HiveService.settingsBox.delete('selectedDurationMinutes');
    }

    state = _copyWith(activeBusiness: business);
  }

  void upgradeBusinessAmount() {
    if (state.activeBusiness == null) return;
    final business = state.activeBusiness!;
    final cost = business.amountUpgradeCost;

    if (state.gold >= cost) {
      spendGold(cost);
      final newBusiness = business.copyWith(
        amountLevel: business.amountLevel + 1,
      );
      setBusiness(newBusiness);
    }
  }

  void upgradeBusinessQuality() {
    if (state.activeBusiness == null) return;
    final business = state.activeBusiness!;
    final cost = business.qualityUpgradeCost;

    if (state.gold >= cost) {
      spendGold(cost);
      final newBusiness = business.copyWith(
        qualityLevel: business.qualityLevel + 1,
      );
      setBusiness(newBusiness);
    }
  }

  void startBusinessProduction(int durationMinutes) {
    if (state.activeBusiness == null) return;
    final business = state.activeBusiness!;

    final now = DateTime.now();
    final finishTime = now.add(Duration(minutes: durationMinutes));

    final newBusiness = business.copyWith(
      productionFinishTime: finishTime,
      selectedDurationMinutes: durationMinutes,
    );
    setBusiness(newBusiness);
  }

  void claimBusinessReward(DateTime now) {
    if (state.activeBusiness == null) return;
    final business = state.activeBusiness!;

    if (business.productionFinishTime == null ||
        business.selectedDurationMinutes == null) {
      return; // Not producing or invalid state
    }

    final durationHours = business.selectedDurationMinutes! / 60.0;
    final amountLevel = business.amountLevel;
    final qualityLevel = business.qualityLevel;

    // Calculate Rewards
    if (business.type == BusinessType.mine) {
      // Mine: Gold
      final gold =
          (300 * durationHours * amountLevel * (1 + 0.2 * qualityLevel))
              .toInt();
      addGold(gold);
      _log.addLog("The Mine produced $gold Gold.", LogType.gold);
    } else if (business.type == BusinessType.farm) {
      // Farm: Gold + Items
      final gold = (100 * durationHours * amountLevel).toInt();
      addGold(gold);
      _log.addLog("The Farm produced $gold Gold.", LogType.gold);

      final numItems = (durationHours * 0.5 * amountLevel).ceil();
      for (int i = 0; i < numItems; i++) {
        // Quality increases rarity chance (10% per level)
        final item = LootFactory.generate(1, rarityBonus: qualityLevel * 10);
        addItem(item);
        _log.addLog("Farm produced: ${item.name}", LogType.loot);
      }
      if (numItems > 0) {
        _feedback.showFloatingText("+$numItems Items", FeedbackType.info);
      }
    } else if (business.type == BusinessType.lodge) {
      // Lodge: Quests
      final numQuests = (durationHours * 0.25 * amountLevel).ceil();
      int questsFound = 0;

      for (int i = 0; i < numQuests; i++) {
        // Quality increases quest difficulty/rewards
        final quest = QuestFactory.generateBounty(
          difficulty: qualityLevel,
          withItemReward: true, // Always give item chance as requested
        );

        // Save Quest
        HiveService.questsBox.put(quest.id, quest);

        // Discover
        discoverSideQuest(quest.id);
        _log.addLog("Scouts found a bounty: ${quest.title}", LogType.info);
        questsFound++;
      }

      if (questsFound > 0) {
        _feedback.showFloatingText("+$questsFound Quests", FeedbackType.info);
        _audio.playGoldSound(); // Or a specific sound
      }
    }

    // Reset production state
    final clearedBusiness = Business(
      type: business.type,
      amountLevel: business.amountLevel,
      qualityLevel: business.qualityLevel,
      lastCollected: now,
      productionFinishTime: null,
      selectedDurationMinutes: null,
      upgrades: business.upgrades,
    );

    setBusiness(clearedBusiness);
  }

  void upgradeVault() {
    // Simple vault upgrade logic for now, maybe costs Ancient Coins or Gold?
    // Let's say it costs 1000 Gold * Level
    final cost = state.vaultLevel * 1000;
    if (state.gold >= cost) {
      spendGold(cost);
      final newLevel = state.vaultLevel + 1;
      HiveService.settingsBox.put('vaultLevel', newLevel);
      state = _copyWith(vaultLevel: newLevel);
    }
  }

  void addToVault(Item item) {
    // Check vault capacity
    final maxSlots = state.vaultCapacity;

    if (state.vaultItems.length < maxSlots) {
      HiveService.vaultBox.add(item);
      state = _copyWith(vaultItems: [...state.vaultItems, item]);
    }
  }

  void removeFromVault(Item item) {
    final key = HiveService.vaultBox.keys.firstWhere(
      (k) => HiveService.vaultBox.get(k)?.id == item.id,
      orElse: () => null,
    );

    if (key != null) {
      HiveService.vaultBox.delete(key);
    }
    state = _copyWith(
      vaultItems: state.vaultItems.where((i) => i.id != item.id).toList(),
    );
  }

  // Phase 4: Artifact Methods
  void addArtifact(String artifactId) {
    if (!state.activeArtifactIds.contains(artifactId)) {
      final newIds = [...state.activeArtifactIds, artifactId];
      HiveService.settingsBox.put('activeArtifactIds', newIds);
      state = _copyWith(activeArtifactIds: newIds);
    }
  }

  void removeArtifact(String artifactId) {
    if (state.activeArtifactIds.contains(artifactId)) {
      final newIds = state.activeArtifactIds
          .where((id) => id != artifactId)
          .toList();
      HiveService.settingsBox.put('activeArtifactIds', newIds);
      state = _copyWith(activeArtifactIds: newIds);
    }
  }

  // Quest Methods
  void completeQuest(String questId) {
    if (!state.completedQuestIds.contains(questId)) {
      final newIds = [...state.completedQuestIds, questId];
      HiveService.settingsBox.put('completedQuestIds', newIds);
      state = _copyWith(completedQuestIds: newIds);
    }

    // Increment completion count
    final currentCount = state.questCompletionCounts[questId] ?? 0;
    final newCount = currentCount + 1;
    final newCounts = Map<String, int>.from(state.questCompletionCounts);
    newCounts[questId] = newCount;

    HiveService.settingsBox.put('questCompletionCounts', newCounts);
    state = _copyWith(questCompletionCounts: newCounts);
  }

  void discoverSideQuest(String questId) {
    if (!state.discoveredSideQuestIds.contains(questId)) {
      final newIds = [...state.discoveredSideQuestIds, questId];
      HiveService.settingsBox.put('discoveredSideQuestIds', newIds);
      state = _copyWith(discoveredSideQuestIds: newIds);
    }
  }

  void updateShopQuests(List<String> questIds) {
    final now = DateTime.now();
    HiveService.settingsBox.put('shopQuestIds', questIds);
    HiveService.settingsBox.put('lastShopRefresh', now.toIso8601String());
    state = _copyWith(shopQuestIds: questIds, lastShopRefresh: now);
  }

  void setNextTavernQuestTime(DateTime time) {
    HiveService.settingsBox.put('nextTavernQuestTime', time.toIso8601String());
    state = _copyWith(nextTavernQuestTime: time);
  }

  void addHint(String questId) {
    final currentHints = state.questHints[questId] ?? 0;
    final newHints = currentHints + 1;
    final newQuestHints = Map<String, int>.from(state.questHints);
    newQuestHints[questId] = newHints;

    HiveService.settingsBox.put('questHints', newQuestHints);
    state = _copyWith(questHints: newQuestHints);
    _feedback.showFloatingText("Hint Acquired!", FeedbackType.success);
    _log.addLog("You found a hint for a legendary quest.", LogType.info);
  }

  // Revised buyShard to handle the logic if we pass the eligible quests
  void buyShard(List<String> eligibleQuestIds) {
    const shardCost = 500;
    if (state.gold < shardCost) {
      _feedback.showFloatingText("Not enough Gold!", FeedbackType.error);
      return;
    }

    if (eligibleQuestIds.isEmpty) {
      _feedback.showFloatingText("No secrets left to find.", FeedbackType.info);
      return;
    }

    spendGold(shardCost);

    // Target the first eligible quest. The caller passes them lowest-difficulty
    // first (P1.4), so a shard always advances the nearest legendary quest
    // instead of landing on a random one and wasting gold.
    addHint(eligibleQuestIds.first);
  }

  /// Spend Ancient Coins on a permanent meta upgrade (P3.1).
  void buyMetaUpgrade(MetaUpgrade upgrade) {
    final level = state.metaLevel(upgrade);
    final cost = MetaUpgradeCatalog.of(upgrade).costAt(level);
    if (cost == null) {
      _feedback.showFloatingText("Already maxed!", FeedbackType.info);
      return;
    }
    if (state.ancientCoins < cost) {
      _feedback.showFloatingText(
        "Not enough Ancient Coins!",
        FeedbackType.error,
      );
      return;
    }

    final newCoins = state.ancientCoins - cost;
    final newLevels = Map<int, int>.from(state.metaUpgradeLevels);
    newLevels[upgrade.index] = level + 1;

    HiveService.settingsBox.put('ancientCoins', newCoins);
    HiveService.settingsBox.put(
      'metaUpgradeLevels',
      newLevels.map((k, v) => MapEntry(k.toString(), v)),
    );
    state = _copyWith(ancientCoins: newCoins, metaUpgradeLevels: newLevels);

    _feedback.showFloatingText(
      "${MetaUpgradeCatalog.of(upgrade).title} upgraded!",
      FeedbackType.success,
    );
    _audio.playGoldSound();
  }

  Future<void> resetGame() async {
    // 1. Calculate Prestige Currency (Legacy meta upgrade boosts the yield).
    final earnedCoins =
        ((state.gold / 10000).floor() * state.metaCoinMultiplier).floor();
    final newAncientCoins = state.ancientCoins + earnedCoins;
    HiveService.settingsBox.put('ancientCoins', newAncientCoins);

    // 2. The Wipe
    await HiveService.heroesBox.clear();
    await HiveService.inventoryBox.clear();
    await HiveService.questsBox.clear(); // Also clear active quests
    await HiveService.logsBox.clear();

    // Reset Gold
    HiveService.settingsBox.put('gold', 0);

    // Reset Business
    HiveService.settingsBox.delete('businessType');
    HiveService.settingsBox.delete('businessAmountLevel');
    HiveService.settingsBox.delete('businessSpeedLevel');
    HiveService.settingsBox.delete('businessLastCollected');

    // Reset Vault Level
    HiveService.settingsBox.put('vaultLevel', 1);

    // Reset Artifacts
    HiveService.settingsBox.delete('activeArtifactIds');

    // Reset Quests
    HiveService.settingsBox.delete('completedQuestIds');
    HiveService.settingsBox.delete('discoveredSideQuestIds');
    HiveService.settingsBox.delete('shopQuestIds');
    HiveService.settingsBox.delete('shopQuestIds');
    HiveService.settingsBox.delete('lastShopRefresh');
    HiveService.settingsBox.delete('nextTavernQuestTime');
    HiveService.settingsBox.delete('inventoryLimit');
    HiveService.settingsBox.delete('questHints');
    HiveService.settingsBox.delete('questCompletionCounts');

    // 3. The Advance
    final newEraIndex = state.currentEraIndex + 1;
    HiveService.settingsBox.put('currentEraIndex', newEraIndex);

    // 4. Reload State

    // Move Vault items to Inventory
    for (var item in state.vaultItems) {
      await HiveService.inventoryBox.add(item);
    }
    await HiveService.vaultBox.clear();

    state = GameState(
      gold: 0,
      lastSaveTime: DateTime.now(),
      inventory: HiveService.inventoryBox.values.toList(),
      currentEraIndex: newEraIndex,
      vaultItems: [],
      ancientCoins: newAncientCoins,
      activeBusiness: null,
      vaultLevel: 1,
      activeArtifactIds: [],
      completedQuestIds: [],
      discoveredSideQuestIds: [],
      shopQuestIds: [],
      lastShopRefresh: null,
      nextTavernQuestTime: null,
      inventoryLimit: 20,
      questHints: {},
      questCompletionCounts: {},
      // Lifetime totals survive prestige — they're cross-run records.
      lifetimeGoldEarned: state.lifetimeGoldEarned,
      lifetimeItemsFound: state.lifetimeItemsFound,
      // The Ancient-Coin meta tree is permanent across prestige.
      metaUpgradeLevels: state.metaUpgradeLevels,
    );
  }

  void debugCycleEra() {
    final nextEra = (state.currentEraIndex + 1) % 3;
    HiveService.settingsBox.put('currentEraIndex', nextEra);
    state = _copyWith(currentEraIndex: nextEra);
  }

  GameState _copyWith({
    int? gold,
    DateTime? lastSaveTime,
    List<Item>? inventory,
    int? currentEraIndex,
    List<Item>? vaultItems,
    int? ancientCoins,
    Business? activeBusiness,
    int? vaultLevel,
    List<String>? activeArtifactIds,
    List<String>? completedQuestIds,
    List<String>? discoveredSideQuestIds,
    List<String>? shopQuestIds,
    DateTime? lastShopRefresh,
    DateTime? nextTavernQuestTime,
    int? inventoryLimit,
    Map<String, int>? questHints,
    Map<String, int>? questCompletionCounts,
    int? lifetimeGoldEarned,
    int? lifetimeItemsFound,
    Map<int, int>? metaUpgradeLevels,
  }) {
    return GameState(
      gold: gold ?? state.gold,
      lastSaveTime: lastSaveTime ?? state.lastSaveTime,
      inventory: inventory ?? state.inventory,
      currentEraIndex: currentEraIndex ?? state.currentEraIndex,
      vaultItems: vaultItems ?? state.vaultItems,
      ancientCoins: ancientCoins ?? state.ancientCoins,
      activeBusiness: activeBusiness ?? state.activeBusiness,
      vaultLevel: vaultLevel ?? state.vaultLevel,
      activeArtifactIds: activeArtifactIds ?? state.activeArtifactIds,
      completedQuestIds: completedQuestIds ?? state.completedQuestIds,
      discoveredSideQuestIds:
          discoveredSideQuestIds ?? state.discoveredSideQuestIds,
      shopQuestIds: shopQuestIds ?? state.shopQuestIds,
      lastShopRefresh: lastShopRefresh ?? state.lastShopRefresh,
      nextTavernQuestTime: nextTavernQuestTime ?? state.nextTavernQuestTime,
      inventoryLimit: inventoryLimit ?? state.inventoryLimit,
      questHints: questHints ?? state.questHints,
      questCompletionCounts:
          questCompletionCounts ?? state.questCompletionCounts,
      lifetimeGoldEarned: lifetimeGoldEarned ?? state.lifetimeGoldEarned,
      lifetimeItemsFound: lifetimeItemsFound ?? state.lifetimeItemsFound,
      metaUpgradeLevels: metaUpgradeLevels ?? state.metaUpgradeLevels,
    );
  }
}
