import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_objective.dart';
import '../models/hero_model.dart';
import '../services/hive_service.dart';
import '../utils/quest_factory.dart';
import 'game_provider.dart';
import 'hero_provider.dart';

/// Immutable snapshot of the day's short-term goals.
class DailyState {
  final String dateKey; // yyyy-mm-dd this state belongs to
  final List<DailyObjective> objectives;
  final List<bool> claimed; // parallel to [objectives]

  // Day-start baselines for each metric (lifetime totals captured at rollover).
  final int baselineQuests;
  final int baselineGold;
  final int baselineItems;
  final int baselineLevels;

  final int loginCount; // total distinct days the player has logged in
  final bool loginClaimedToday;
  final List<String> bountyQuestIds; // free bounties offered today

  const DailyState({
    required this.dateKey,
    required this.objectives,
    required this.claimed,
    required this.baselineQuests,
    required this.baselineGold,
    required this.baselineItems,
    required this.baselineLevels,
    required this.loginCount,
    required this.loginClaimedToday,
    required this.bountyQuestIds,
  });

  int baselineFor(DailyObjectiveType type) {
    switch (type) {
      case DailyObjectiveType.completeQuests:
        return baselineQuests;
      case DailyObjectiveType.earnGold:
        return baselineGold;
      case DailyObjectiveType.findItems:
        return baselineItems;
      case DailyObjectiveType.gainLevels:
        return baselineLevels;
    }
  }

  DailyState copyWith({List<bool>? claimed, bool? loginClaimedToday}) {
    return DailyState(
      dateKey: dateKey,
      objectives: objectives,
      claimed: claimed ?? this.claimed,
      baselineQuests: baselineQuests,
      baselineGold: baselineGold,
      baselineItems: baselineItems,
      baselineLevels: baselineLevels,
      loginCount: loginCount,
      loginClaimedToday: loginClaimedToday ?? this.loginClaimedToday,
      bountyQuestIds: bountyQuestIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'claimed': claimed,
        'baselineQuests': baselineQuests,
        'baselineGold': baselineGold,
        'baselineItems': baselineItems,
        'baselineLevels': baselineLevels,
        'loginCount': loginCount,
        'loginClaimedToday': loginClaimedToday,
        'bountyQuestIds': bountyQuestIds,
      };

  factory DailyState.fromJson(Map<String, dynamic> j) => DailyState(
        dateKey: j['dateKey'] as String,
        objectives: (j['objectives'] as List)
            .map((e) => DailyObjective.fromJson(e as Map<String, dynamic>))
            .toList(),
        claimed: (j['claimed'] as List).map((e) => e as bool).toList(),
        baselineQuests: j['baselineQuests'] as int,
        baselineGold: j['baselineGold'] as int,
        baselineItems: j['baselineItems'] as int,
        baselineLevels: j['baselineLevels'] as int,
        loginCount: j['loginCount'] as int,
        loginClaimedToday: j['loginClaimedToday'] as bool,
        bountyQuestIds:
            (j['bountyQuestIds'] as List).map((e) => e as String).toList(),
      );
}

/// Daily-login reward calendar (gold), forgiving: it advances by total logins,
/// not a fragile consecutive streak, so a missed day never resets progress.
const List<int> kLoginRewards = [100, 150, 200, 300, 400, 500, 1000];

const String _dailyKey = 'dailyState';
const int _kDailyBounties = 2;

final dailyProvider = StateNotifierProvider<DailyNotifier, DailyState>((ref) {
  return DailyNotifier(ref);
});

class DailyNotifier extends StateNotifier<DailyState> {
  final Ref ref;

  DailyNotifier(this.ref) : super(_loadOrSeed(ref)) {
    // If the persisted state is from a previous day, roll over now.
    if (state.dateKey != _todayKey()) {
      _rollover();
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  static DailyState? _readPersisted() {
    final raw = HiveService.settingsBox.get(_dailyKey);
    if (raw is! String) return null;
    try {
      return DailyState.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Load persisted state if present; otherwise an empty placeholder for today
  /// (the constructor immediately rolls it over to capture real baselines).
  static DailyState _loadOrSeed(Ref ref) {
    final persisted = _readPersisted();
    if (persisted != null) return persisted;
    return DailyState(
      dateKey: '',
      objectives: const [],
      claimed: const [],
      baselineQuests: 0,
      baselineGold: 0,
      baselineItems: 0,
      baselineLevels: 0,
      loginCount: 0,
      loginClaimedToday: false,
      bountyQuestIds: const [],
    );
  }

  void _persist() {
    HiveService.settingsBox.put(_dailyKey, json.encode(state.toJson()));
  }

  /// If a new day has begun, refresh objectives/bounties/login. Safe to call
  /// repeatedly (no-op when already on today's state).
  void refresh() {
    if (state.dateKey != _todayKey()) _rollover();
  }

  void _rollover() {
    final game = ref.read(gameProvider);
    final heroes = ref.read(heroProvider);
    final today = _todayKey();

    final objectives = DailyObjective.forDate(today);
    final bountyIds = _generateBounties(heroes);

    state = DailyState(
      dateKey: today,
      objectives: objectives,
      claimed: List<bool>.filled(objectives.length, false),
      baselineQuests: _questsDone(game),
      baselineGold: game.lifetimeGoldEarned,
      baselineItems: game.lifetimeItemsFound,
      baselineLevels: _levelSum(heroes),
      loginCount: state.loginCount + 1,
      loginClaimedToday: false,
      bountyQuestIds: bountyIds,
    );
    _persist();
  }

  /// Two free, level-appropriate bounties, persisted to the quest box so they
  /// can be accepted into the player's list at no cost.
  List<String> _generateBounties(List<HeroModel> heroes) {
    final level = heroes.isEmpty
        ? 1
        : heroes.map((h) => h.level).reduce((a, b) => a > b ? a : b);
    final ids = <String>[];
    for (int i = 0; i < _kDailyBounties; i++) {
      final quest = QuestFactory.generateBounty(
        difficulty: level < 1 ? 1 : level,
        withItemReward: true,
      );
      HiveService.questsBox.put(quest.id, quest);
      ids.add(quest.id);
    }
    return ids;
  }

  static int _questsDone(GameState g) =>
      g.questCompletionCounts.values.fold(0, (sum, c) => sum + c);

  static int _levelSum(List<HeroModel> heroes) =>
      heroes.fold(0, (sum, h) => sum + h.level);

  /// Current lifetime metric for [type], for progress calculation.
  int currentMetric(DailyObjectiveType type) {
    final game = ref.read(gameProvider);
    switch (type) {
      case DailyObjectiveType.completeQuests:
        return _questsDone(game);
      case DailyObjectiveType.earnGold:
        return game.lifetimeGoldEarned;
      case DailyObjectiveType.findItems:
        return game.lifetimeItemsFound;
      case DailyObjectiveType.gainLevels:
        return _levelSum(ref.read(heroProvider));
    }
  }

  int progressOf(int index) {
    final obj = state.objectives[index];
    return obj.progress(currentMetric(obj.type), state.baselineFor(obj.type));
  }

  bool isComplete(int index) {
    final obj = state.objectives[index];
    return obj.isComplete(currentMetric(obj.type), state.baselineFor(obj.type));
  }

  bool canClaim(int index) => isComplete(index) && !state.claimed[index];

  void claimObjective(int index) {
    if (!canClaim(index)) return;
    final reward = state.objectives[index].rewardGold;
    ref.read(gameProvider.notifier).addGold(reward);
    final newClaimed = [...state.claimed];
    newClaimed[index] = true;
    state = state.copyWith(claimed: newClaimed);
    _persist();
  }

  int get loginReward =>
      kLoginRewards[(state.loginCount - 1).clamp(0, 1 << 30) % kLoginRewards.length];

  void claimLoginReward() {
    if (state.loginClaimedToday) return;
    ref.read(gameProvider.notifier).addGold(loginReward);
    state = state.copyWith(loginClaimedToday: true);
    _persist();
  }

  /// Accept a free daily bounty into the player's quest list.
  void acceptBounty(String questId) {
    ref.read(gameProvider.notifier).discoverSideQuest(questId);
  }
}
