import 'package:hive/hive.dart';

import '../data/museum_items.dart';

part 'museum_state.g.dart';

@HiveType(typeId: 8)
class MuseumState {
  @HiveField(0)
  final List<String> unlockedItemIds;

  @HiveField(1)
  final List<String> unlockedEndings;

  MuseumState({required this.unlockedItemIds, required this.unlockedEndings});

  /// Fraction (0.0–1.0) of curated museum items that have been unlocked.
  /// Counts only IDs that correspond to real museum items so procedural loot
  /// IDs can never push completion above 100%.
  double get completionPercentage {
    final total = MuseumItems.allItems.length;
    if (total == 0) return 0;
    final known = unlockedItemIds
        .where((id) => MuseumItems.getById(id) != null)
        .length;
    return known / total;
  }
}
