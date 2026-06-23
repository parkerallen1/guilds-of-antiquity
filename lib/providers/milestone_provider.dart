import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/milestone.dart';
import '../services/hive_service.dart';
import 'game_provider.dart';
import 'hero_provider.dart';

const String _milestoneKey = 'milestoneClaims';

/// State = how many tiers have been claimed on each track (track index -> count).
final milestoneProvider =
    StateNotifierProvider<MilestoneNotifier, Map<int, int>>((ref) {
  return MilestoneNotifier(ref);
});

class MilestoneNotifier extends StateNotifier<Map<int, int>> {
  final Ref ref;

  MilestoneNotifier(this.ref) : super(_load());

  static Map<int, int> _load() {
    final raw = HiveService.settingsBox.get(_milestoneKey);
    if (raw is! String) return {};
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  void _persist() {
    HiveService.settingsBox.put(
      _milestoneKey,
      json.encode(state.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  int claimedCount(MilestoneTrack track) => state[track.index] ?? 0;

  /// Current lifetime value driving a track's progress.
  int currentValue(MilestoneTrack track) {
    final game = ref.read(gameProvider);
    switch (track) {
      case MilestoneTrack.questsCompleted:
        return game.questCompletionCounts.values.fold(0, (s, c) => s + c);
      case MilestoneTrack.goldEarned:
        return game.lifetimeGoldEarned;
      case MilestoneTrack.itemsFound:
        return game.lifetimeItemsFound;
      case MilestoneTrack.heroLevel:
        final heroes = ref.read(heroProvider);
        return heroes.isEmpty
            ? 0
            : heroes.map((h) => h.level).reduce((a, b) => a > b ? a : b);
    }
  }

  bool canClaim(MilestoneTrack track) {
    final def = MilestoneCatalog.byTrack(track);
    return def.canClaim(currentValue(track), claimedCount(track));
  }

  bool get hasClaimable =>
      MilestoneCatalog.tracks.any((d) => canClaim(d.track));

  void claim(MilestoneTrack track) {
    if (!canClaim(track)) return;
    final def = MilestoneCatalog.byTrack(track);
    final tier = def.nextTier(claimedCount(track))!;
    ref.read(gameProvider.notifier).addGold(tier.rewardGold);
    state = {...state, track.index: claimedCount(track) + 1};
    _persist();
  }
}
