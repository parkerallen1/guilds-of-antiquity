import 'dart:math';

enum BusinessType {
  farm, // Slow gold, more items
  mine, // Pure gold
  lodge, // Finds quests
}

enum BusinessUpgrade {
  // Farm Upgrades
  fertilizer, // +10% Item Quality
  marketStall, // +20% Gold from Items
  // Mine Upgrades
  deepShafts, // +20% Gold Amount
  conveyorBelt, // +10% Speed (Deprecated/Changed?) -> Now Quality?
  // Lodge Upgrades
  scouts, // +20% Quest Rarity
  network, // +10% Quest Find Speed (Deprecated?) -> Now Quality?
}

class Business {
  final BusinessType type;
  final int amountLevel; // Quantity
  final int qualityLevel; // Quality (Replaces speedLevel)
  final DateTime? lastCollected; // Used for "Claimed" timestamp or just history
  final DateTime? productionFinishTime; // When the current job finishes
  final int? selectedDurationMinutes; // Duration of current job
  final List<BusinessUpgrade> upgrades;

  const Business({
    required this.type,
    this.amountLevel = 1,
    this.qualityLevel = 1,
    this.lastCollected,
    this.productionFinishTime,
    this.selectedDurationMinutes,
    this.upgrades = const [],
  });

  String get name {
    switch (type) {
      case BusinessType.farm:
        return 'The Farm';
      case BusinessType.mine:
        return 'The Mine';
      case BusinessType.lodge:
        return 'Hunter\'s Lodge';
    }
  }

  String get description {
    switch (type) {
      case BusinessType.farm:
        return 'Produces Items and some Gold.';
      case BusinessType.mine:
        return 'Produces large amounts of Gold.';
      case BusinessType.lodge:
        return 'Discovers new Quests.';
    }
  }

  // Cost to upgrade Amount (Quantity)
  int get amountUpgradeCost {
    return (100 * pow(1.5, amountLevel - 1)).toInt();
  }

  // Cost to upgrade Quality
  int get qualityUpgradeCost {
    return (100 * pow(1.5, qualityLevel - 1)).toInt();
  }

  Business copyWith({
    int? amountLevel,
    int? qualityLevel,
    DateTime? lastCollected,
    DateTime? productionFinishTime,
    int? selectedDurationMinutes,
    List<BusinessUpgrade>? upgrades,
  }) {
    return Business(
      type: type,
      amountLevel: amountLevel ?? this.amountLevel,
      qualityLevel: qualityLevel ?? this.qualityLevel,
      lastCollected: lastCollected ?? this.lastCollected,
      productionFinishTime: productionFinishTime ?? this.productionFinishTime,
      selectedDurationMinutes:
          selectedDurationMinutes ?? this.selectedDurationMinutes,
      upgrades: upgrades ?? this.upgrades,
    );
  }
}
