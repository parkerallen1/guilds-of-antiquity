import '../models/hero_model.dart';

/// Pure, Flutter-free math for catching a hero up after the app was closed.
///
/// Kept separate from the orchestration ([OfflineService]) so the HP math can
/// be unit-tested without Hive or a Flutter binding.
class OfflineProgress {
  /// HP a hero regenerates over [elapsed] of offline time, at the live game's
  /// base passive-heal rate (a full bar in 3600s, scaled by Speed — the same
  /// rate the ticker uses while idle/questing). Never overshoots maxHp, and
  /// returns 0 if the hero is already full or [elapsed] is non-positive.
  static int healedHp(HeroModel hero, Duration elapsed) {
    if (hero.hp >= hero.maxHp || elapsed.inSeconds <= 0) return 0;
    final double speedFactor = 100.0 / (100.0 + hero.totalSpd);
    final double healPerSec = hero.maxHp / (3600.0 * speedFactor);
    final int regen = (healPerSec * elapsed.inSeconds).round();
    final int newHp = (hero.hp + regen).clamp(0, hero.maxHp);
    return newHp - hero.hp;
  }
}
