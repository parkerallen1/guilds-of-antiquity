/// One main-story gate being cleared for the first time.
class GateClear {
  final String questId;
  final int difficulty;
  final int atAction; // how many quest attempts had been made
  final double atSeconds; // virtual game-time elapsed
  final int heroLevel;
  GateClear(this.questId, this.difficulty, this.atAction, this.atSeconds,
      this.heroLevel);
}

/// Everything we learned from one full playthrough.
class RunResult {
  final String policy;
  bool reachedEnd = false;
  int actions = 0;
  int successes = 0;
  int failures = 0;
  int downs = 0;
  int replayAttempts = 0;
  int shardsBought = 0;
  int totalGoldEarned = 0;
  int finalLevel = 1;
  double questingSeconds = 0;
  double healingSeconds = 0;
  int maxSingleQuestReplays = 0;
  String? stoppedReason;
  final List<GateClear> gates = [];

  RunResult(this.policy);

  double get totalSeconds => questingSeconds + healingSeconds;
  double get totalHours => totalSeconds / 3600.0;
  double get successRate => actions == 0 ? 0 : successes / actions;
}

double median(List<double> xs) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  final mid = s.length ~/ 2;
  return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}

double mean(List<double> xs) =>
    xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
