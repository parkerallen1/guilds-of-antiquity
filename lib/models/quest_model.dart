import 'package:hive/hive.dart';

part 'quest_model.g.dart';

@HiveType(typeId: 2)
class Quest {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int difficulty;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final int goldReward;

  @HiveField(5)
  final int xpReward;

  @HiveField(6)
  final double dropRate;

  @HiveField(7)
  final String description;

  @HiveField(8)
  final bool isMainQuest;

  @HiveField(9)
  final String? requiredQuestId;

  @HiveField(10)
  final double mapX;

  @HiveField(11)
  final double mapY;

  @HiveField(12)
  final List<String> lore;

  @HiveField(13)
  final String? nextQuestId;

  @HiveField(14)
  final bool isReplayable;

  @HiveField(15)
  final String? specialItemReward;

  @HiveField(16)
  final int? repeatGoldReward;

  @HiveField(17)
  final int? repeatXpReward;

  @HiveField(18)
  final String? specialItemDescription;

  @HiveField(19)
  final int requiredHints;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.durationSeconds,
    required this.goldReward,
    required this.xpReward,
    required this.dropRate,
    required this.isMainQuest,
    this.requiredQuestId,
    this.mapX = 0.0,
    this.mapY = 0.0,
    this.lore = const [],
    this.nextQuestId,
    this.isReplayable = false,
    this.specialItemReward,
    this.repeatGoldReward,
    this.repeatXpReward,
    this.specialItemDescription,
    this.requiredHints = 0,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as int,
      durationSeconds: json['durationSeconds'] as int,
      goldReward: json['goldReward'] as int,
      xpReward: json['xpReward'] as int,
      dropRate: (json['dropRate'] as num).toDouble(),
      isMainQuest: json['isMainQuest'] as bool,
      requiredQuestId: json['requiredQuestId'] as String?,
      mapX: (json['mapX'] as num?)?.toDouble() ?? 0.0,
      mapY: (json['mapY'] as num?)?.toDouble() ?? 0.0,
      lore:
          (json['lore'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      nextQuestId: json['nextQuestId'] as String?,
      isReplayable: json['isReplayable'] as bool? ?? false,
      specialItemReward: json['specialItemReward'] as String?,
      repeatGoldReward: json['repeatGoldReward'] as int?,
      repeatXpReward: json['repeatXpReward'] as int?,
      specialItemDescription: json['specialItemDescription'] as String?,
      requiredHints: json['requiredHints'] as int? ?? 0,
    );
  }
}
