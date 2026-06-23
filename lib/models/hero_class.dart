/// Mechanical identity for each hero class (P3.4). Classes used to differ only
/// in their starting-stat ranges; each now carries an ongoing passive that
/// complements its stat lean, applied in the pure quest resolver / combat math.
class HeroClassPassive {
  final String name;
  final String description;

  /// Multiplier on quest gold earned (Thief).
  final double goldMult;

  /// Multiplier on quest XP earned (Mage).
  final double xpMult;

  /// Additive bonus to loot drop chance (Ranger).
  final double dropBonus;

  /// Multiplier on damage taken; <1 means tankier (Warrior).
  final double damageTakenMult;

  const HeroClassPassive({
    required this.name,
    required this.description,
    this.goldMult = 1.0,
    this.xpMult = 1.0,
    this.dropBonus = 0.0,
    this.damageTakenMult = 1.0,
  });
}

class HeroClasses {
  static const HeroClassPassive _none = HeroClassPassive(
    name: 'No Specialty',
    description: 'No class passive.',
  );

  static const Map<String, HeroClassPassive> _passives = {
    'Warrior': HeroClassPassive(
      name: 'Battle-Hardened',
      description: 'Takes 20% less damage in combat.',
      damageTakenMult: 0.8,
    ),
    'Ranger': HeroClassPassive(
      name: 'Keen Eye',
      description: '+8% loot drop chance.',
      dropBonus: 0.08,
    ),
    'Mage': HeroClassPassive(
      name: 'Arcane Insight',
      description: '+25% XP from quests.',
      xpMult: 1.25,
    ),
    'Thief': HeroClassPassive(
      name: 'Plunder',
      description: '+25% gold from quests.',
      goldMult: 1.25,
    ),
  };

  /// The passive for [classType], or a neutral one for unknown classes (e.g.
  /// the simulator's 'Mercenary', which keeps balance runs class-agnostic).
  static HeroClassPassive of(String classType) =>
      _passives[classType] ?? _none;
}
