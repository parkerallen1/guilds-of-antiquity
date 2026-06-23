/// Museum collections grouped by Era. Completing a set (unlocking every item)
/// awards its Artifact — the earn path that was previously missing (P3.2), and
/// since the Artifacts are powerful permanent passives, this also gives set
/// completion a real, lasting reward (P3.3).
class MuseumSet {
  final String id;
  final String title;
  final List<String> itemIds;
  final String artifactId; // matches GameState.activeArtifactIds ids
  final String artifactName;
  final String rewardDescription;

  const MuseumSet({
    required this.id,
    required this.title,
    required this.itemIds,
    required this.artifactId,
    required this.artifactName,
    required this.rewardDescription,
  });

  /// True once every item in the set has been unlocked.
  bool isComplete(List<String> unlockedItemIds) =>
      itemIds.every(unlockedItemIds.contains);

  int unlockedCount(List<String> unlockedItemIds) =>
      itemIds.where(unlockedItemIds.contains).length;
}

class MuseumSets {
  static const List<MuseumSet> all = [
    MuseumSet(
      id: 'age_of_iron',
      title: 'Age of Iron',
      itemIds: [
        'whispering_stone_fragment',
        'corrupted_root',
        'bandit_badge',
      ],
      artifactId: 'greed_coin',
      artifactName: 'Greed Coin',
      rewardDescription: 'Doubles all gold gain.',
    ),
    MuseumSet(
      id: 'age_of_shadows',
      title: 'Age of Shadows',
      itemIds: [
        'frozen_heart',
        'void_essence',
        'ash_king_head',
      ],
      artifactId: 'chrono_dial',
      artifactName: 'Chrono Dial',
      rewardDescription: 'Halves all quest durations.',
    ),
    MuseumSet(
      id: 'age_of_arcanum',
      title: 'Age of Arcanum',
      itemIds: [
        'thrall_helmet',
        'crown_eclipse',
        'shard_reality',
        'abdication_ring',
        'tear_bride',
        'thorne_dagger',
      ],
      artifactId: 'phoenix_feather',
      artifactName: 'Phoenix Feather',
      rewardDescription: 'Cheats death once when a hero would fall.',
    ),
  ];

  /// The set that [itemId] belongs to, or null if it isn't part of any set.
  static MuseumSet? setContaining(String itemId) {
    for (final s in all) {
      if (s.itemIds.contains(itemId)) return s;
    }
    return null;
  }
}
