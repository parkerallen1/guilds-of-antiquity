import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/quest_model.dart';

class QuestFactory {
  static final Random _random = Random();

  static Quest generateBounty({
    int difficulty = 1,
    bool withItemReward = false,
  }) {
    final id = const Uuid().v4();
    final target = _pick([
      "Goblin King",
      "Bandit Leader",
      "Dire Wolf",
      "Shadow Stalker",
      "Rogue Mage",
      "Ancient Golem",
      "Corrupted Knight",
    ]);

    final location = _pick([
      "Dark Forest",
      "Abandoned Mine",
      "Ruined Temple",
      "Misty Swamp",
      "High Peaks",
    ]);

    final title = "Bounty: $target";
    final description = "Hunt down the $target in the $location.";

    // Rewards
    final goldReward = 100 * difficulty + _random.nextInt(50 * difficulty);
    final xpReward = 50 * difficulty + _random.nextInt(25 * difficulty);

    String? specialItem;
    String? specialItemDesc;

    if (withItemReward) {
      specialItem =
          "Mystery Item"; // The game logic will generate a real item when completed
      specialItemDesc = "A reward for this bounty.";
    }

    return Quest(
      id: id,
      title: title,
      description: description,
      difficulty: difficulty,
      durationSeconds: 60 * 5, // 5 minutes base duration for questing
      goldReward: goldReward,
      xpReward: xpReward,
      dropRate: 0.5, // High drop rate for bounty
      isMainQuest: false,
      specialItemReward: specialItem,
      specialItemDescription: specialItemDesc,
      isReplayable: false,
    );
  }

  static String _pick(List<String> options) {
    return options[_random.nextInt(options.length)];
  }
}
