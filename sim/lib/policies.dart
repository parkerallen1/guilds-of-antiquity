import '../../lib/models/hero_model.dart';

/// A play style. Controls two decisions a human makes constantly:
///  - how risky to be about attempting the next main-story quest, and
///  - where to spend upgrade points.
abstract class Policy {
  String get name;

  /// Minimum success % (0-100) required before the bot will attempt the next
  /// gated main-story quest instead of grinding side quests to level up.
  double get mainAttemptThreshold;

  /// Will this policy spend gold on Mysterious Shards to unlock a hint-gated
  /// main quest that is otherwise blocking story progress?
  bool get buysHints => true;

  /// Which stat to put the next upgrade point into: 'str' | 'spd' | 'hp' | 'luck'.
  String chooseStat(HeroModel hero);

  static Policy byName(String n) {
    switch (n) {
      case 'rush_story':
        return RushStory();
      case 'balanced':
        return Balanced();
      case 'speed_stacker':
        return SpeedStacker();
      case 'greedy_gold':
        return GreedyGold();
      case 'tank':
        return Tank();
      default:
        throw ArgumentError('Unknown policy: $n');
    }
  }

  static List<String> get all =>
      ['rush_story', 'balanced', 'speed_stacker', 'greedy_gold', 'tank'];
}

/// Aggressive: pushes the story at lower odds, builds Strength to win fights.
class RushStory extends Policy {
  @override
  String get name => 'rush_story';
  @override
  double get mainAttemptThreshold => 65;
  @override
  String chooseStat(HeroModel hero) {
    // Mostly Strength, a little HP to survive.
    if (hero.maxHp < hero.strength * 12) return 'hp';
    return 'str';
  }
}

/// Even spread across all four stats.
class Balanced extends Policy {
  @override
  String get name => 'balanced';
  @override
  double get mainAttemptThreshold => 75;
  @override
  String chooseStat(HeroModel hero) {
    // Count total points spent so the cycle actually advances on every pick
    // (HP grows maxHp by 10, the others by 1).
    final spent = (hero.strength - 5) +
        (hero.speed - 5) +
        (hero.luck ?? 0) +
        ((hero.maxHp - 100) ~/ 10);
    switch (spent % 4) {
      case 0:
        return 'str';
      case 1:
        return 'spd';
      case 2:
        return 'hp';
      default:
        return 'luck';
    }
  }
}

/// Stacks Speed to compress quest time (farm faster), then Strength.
class SpeedStacker extends Policy {
  @override
  String get name => 'speed_stacker';
  @override
  double get mainAttemptThreshold => 70;
  @override
  String chooseStat(HeroModel hero) {
    if (hero.speed < 100) return 'spd';
    if (hero.maxHp < 200) return 'hp';
    return 'str';
  }
}

/// Optimises gold throughput: Speed for fast farming, Luck for drops.
class GreedyGold extends Policy {
  @override
  String get name => 'greedy_gold';
  @override
  double get mainAttemptThreshold => 70;
  @override
  String chooseStat(HeroModel hero) {
    if (hero.speed < 60) return 'spd';
    if ((hero.luck ?? 0) < 40) return 'luck';
    return 'str';
  }
}

/// Survival-first: HP and Strength, takes story fights at low odds.
class Tank extends Policy {
  @override
  String get name => 'tank';
  @override
  double get mainAttemptThreshold => 60;
  @override
  String chooseStat(HeroModel hero) {
    if (hero.maxHp < hero.strength * 18) return 'hp';
    return 'str';
  }
}
