import 'dart:math';

/// Permanent, cross-run upgrades bought with Ancient Coins (earned on prestige).
/// This is the meta-progression spine: a previously dead currency now buys
/// lasting power that persists through every prestige.
enum MetaUpgrade { greed, fortune, haste, scholar, vigor, legacy }

class MetaUpgradeDef {
  final MetaUpgrade type;
  final String title;
  final String description;
  final String effectSuffix; // e.g. "gold gain"
  final int maxLevel;
  final int baseCost; // Ancient Coins for level 0 -> 1
  final double costGrowth; // multiplicative cost growth per level
  final double perLevel; // effect fraction added per level

  const MetaUpgradeDef({
    required this.type,
    required this.title,
    required this.description,
    required this.effectSuffix,
    required this.maxLevel,
    required this.baseCost,
    required this.costGrowth,
    required this.perLevel,
  });

  /// Ancient-coin cost to buy the next level from [level], or null if maxed.
  int? costAt(int level) =>
      level >= maxLevel ? null : (baseCost * pow(costGrowth, level)).round();

  /// Cumulative effect fraction at [level] (e.g. 0.40 = +40%).
  double valueAt(int level) => perLevel * level;

  /// Human-readable effect at [level], e.g. "+40% gold gain".
  String effectLabel(int level) =>
      "+${(valueAt(level) * 100).round()}% $effectSuffix";
}

class MetaUpgradeCatalog {
  static const Map<MetaUpgrade, MetaUpgradeDef> _defs = {
    MetaUpgrade.greed: MetaUpgradeDef(
      type: MetaUpgrade.greed,
      title: 'Greed',
      description: 'Every coin earned is worth more.',
      effectSuffix: 'gold gain',
      maxLevel: 10,
      baseCost: 3,
      costGrowth: 1.5,
      perLevel: 0.10,
    ),
    MetaUpgrade.fortune: MetaUpgradeDef(
      type: MetaUpgrade.fortune,
      title: 'Fortune',
      description: 'Quests are likelier to drop loot.',
      effectSuffix: 'drop chance',
      maxLevel: 10,
      baseCost: 3,
      costGrowth: 1.5,
      perLevel: 0.02,
    ),
    MetaUpgrade.haste: MetaUpgradeDef(
      type: MetaUpgrade.haste,
      title: 'Haste',
      description: 'Heroes finish quests faster.',
      effectSuffix: 'quest speed',
      maxLevel: 10,
      baseCost: 3,
      costGrowth: 1.5,
      perLevel: 0.05,
    ),
    MetaUpgrade.scholar: MetaUpgradeDef(
      type: MetaUpgrade.scholar,
      title: 'Scholar',
      description: 'Heroes learn from every battle.',
      effectSuffix: 'XP gain',
      maxLevel: 10,
      baseCost: 3,
      costGrowth: 1.5,
      perLevel: 0.10,
    ),
    MetaUpgrade.vigor: MetaUpgradeDef(
      type: MetaUpgrade.vigor,
      title: 'Vigor',
      description: 'Heroes recover their wounds faster.',
      effectSuffix: 'healing rate',
      maxLevel: 10,
      baseCost: 3,
      costGrowth: 1.5,
      perLevel: 0.15,
    ),
    MetaUpgrade.legacy: MetaUpgradeDef(
      type: MetaUpgrade.legacy,
      title: 'Legacy',
      description: 'Each new age leaves you richer in Ancient Coins.',
      effectSuffix: 'Ancient Coins on prestige',
      maxLevel: 10,
      baseCost: 5,
      costGrowth: 1.6,
      perLevel: 0.15,
    ),
  };

  static MetaUpgradeDef of(MetaUpgrade u) => _defs[u]!;
  static List<MetaUpgrade> get all => MetaUpgrade.values;
}
