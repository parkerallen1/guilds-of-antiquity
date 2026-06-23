import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../providers/hero_provider.dart';
import '../engine/offline_progress.dart';
import 'hive_service.dart';

/// Summary of what accrued while the app was closed, shown in the
/// "Welcome Back" dialog.
class OfflineReport {
  final Duration awayFor;

  /// Hero display name -> HP recovered while away (only heroes that healed).
  final Map<String, int> hpHealedByHero;

  /// Net results of auto-collecting a business job that finished while away.
  final int businessGold;
  final int businessItems;
  final int businessQuests;
  final bool businessCollected;

  const OfflineReport({
    required this.awayFor,
    this.hpHealedByHero = const {},
    this.businessGold = 0,
    this.businessItems = 0,
    this.businessQuests = 0,
    this.businessCollected = false,
  });

  int get totalHpHealed =>
      hpHealedByHero.values.fold(0, (sum, hp) => sum + hp);

  /// Only surface the dialog when the player was away long enough AND
  /// something actually happened — no point popping it after a quick tab-out.
  bool get isMeaningful =>
      awayFor.inSeconds >= _minAwaySeconds &&
      (totalHpHealed > 0 || businessCollected);

  static const int _minAwaySeconds = 60;
}

/// Persists when the app was last active and, on return, catches the game up:
/// heroes recover the HP they would have regenerated, and a business job that
/// finished while away is auto-collected. Returns an [OfflineReport] for the
/// UI to summarise.
class OfflineService {
  final WidgetRef ref;
  OfflineService(this.ref);

  static const String _lastSeenKey = 'lastSeenTime';

  /// Stamp "now" as the last time the app was active. Call on pause/close and
  /// after a catch-up so the next return measures from the right point.
  void recordSeen() {
    HiveService.settingsBox.put(
      _lastSeenKey,
      DateTime.now().toIso8601String(),
    );
  }

  DateTime? _readLastSeen() {
    final raw = HiveService.settingsBox.get(_lastSeenKey);
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  /// Apply offline catch-up and return a report (null if there was nothing to
  /// report — e.g. first launch, or away only briefly with full HP and no
  /// finished business job). Always re-stamps the last-seen time.
  OfflineReport? catchUp() {
    final lastSeen = _readLastSeen();
    final now = DateTime.now();

    if (lastSeen == null) {
      recordSeen();
      return null;
    }

    final elapsed = now.difference(lastSeen);
    if (elapsed.inSeconds < OfflineReport._minAwaySeconds) {
      recordSeen();
      return null;
    }

    // 1. Heal heroes by the time they spent resting offline.
    final heroNotifier = ref.read(heroProvider.notifier);
    final heroes = ref.read(heroProvider);
    final healed = <String, int>{};
    for (final hero in heroes) {
      final hp = OfflineProgress.healedHp(hero, elapsed);
      if (hp > 0) {
        heroNotifier.updateHero(hero.copyWith(hp: hero.hp + hp));
        healed[hero.name] = hp;
      }
    }

    // 2. Auto-collect a business job that genuinely finished while away.
    final gameNotifier = ref.read(gameProvider.notifier);
    final before = ref.read(gameProvider);
    final business = before.activeBusiness;
    bool collected = false;
    if (business?.productionFinishTime != null &&
        now.isAfter(business!.productionFinishTime!)) {
      gameNotifier.claimBusinessReward(now);
      collected = true;
    }
    final after = ref.read(gameProvider);

    recordSeen();

    return OfflineReport(
      awayFor: elapsed,
      hpHealedByHero: healed,
      businessGold: collected ? (after.gold - before.gold) : 0,
      businessItems:
          collected ? (after.inventory.length - before.inventory.length) : 0,
      businessQuests: collected
          ? (after.discoveredSideQuestIds.length -
                before.discoveredSideQuestIds.length)
          : 0,
      businessCollected: collected,
    );
  }
}
