import 'package:hive/hive.dart';

part 'museum_state.g.dart';

@HiveType(typeId: 8)
class MuseumState {
  @HiveField(0)
  final List<String> unlockedItemIds; // Using List because Set might have issues with Hive sometimes, but Set is better logically. Let's use List for safety and convert to Set in getter if needed. Actually Hive supports List well.

  @HiveField(1)
  final List<String> unlockedEndings;

  MuseumState({required this.unlockedItemIds, required this.unlockedEndings});

  double get completionPercentage =>
      unlockedItemIds.length / 100.0; // Assuming 100 items total
}
