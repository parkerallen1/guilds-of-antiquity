import '../models/quest_model.dart';

class QuestLogic {
  static Quest getAdjustedQuest(Quest original, int completions) {
    if (completions < 10) {
      return original;
    }

    int levelBonus = 0;
    double rewardMultiplier = 1.0;

    if (completions >= 50) {
      levelBonus = 3;
      rewardMultiplier = 2.0;
    } else if (completions >= 25) {
      levelBonus = 2;
      rewardMultiplier = 1.5;
    } else if (completions >= 10) {
      levelBonus = 1;
      rewardMultiplier = 1.2;
    }

    // Calculate new rewards
    final newGold = (original.goldReward * rewardMultiplier).round();
    final newXp = (original.xpReward * rewardMultiplier).round();
    final newRepeatGold = original.repeatGoldReward != null
        ? (original.repeatGoldReward! * rewardMultiplier).round()
        : (newGold ~/ 2);
    final newRepeatXp = original.repeatXpReward != null
        ? (original.repeatXpReward! * rewardMultiplier).round()
        : (newXp ~/ 2);

    // Create a new quest object with adjusted stats
    // We use a trick to override the getters or just create a new instance
    // Since Quest is immutable, we create a new one.
    return Quest(
      id: original.id,
      title: original.title, // Maybe add suffix? e.g. " (Elite)"
      description: original.description,
      difficulty: original.difficulty + levelBonus,
      durationSeconds: original.durationSeconds,
      goldReward: newGold,
      xpReward: newXp,
      dropRate: original.dropRate, // Could increase drop rate too?
      isMainQuest: original.isMainQuest,
      requiredQuestId: original.requiredQuestId,
      mapX: original.mapX,
      mapY: original.mapY,
      lore: original.lore,
      nextQuestId: original.nextQuestId,
      isReplayable: original.isReplayable,
      specialItemReward: original.specialItemReward,
      repeatGoldReward: newRepeatGold,
      repeatXpReward: newRepeatXp,
      specialItemDescription: original.specialItemDescription,
      requiredHints: original.requiredHints,
    );
  }
}
