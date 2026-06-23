/// Long-term, one-time achievement tracks. Unlike daily objectives, milestones
/// are permanent and measured against lifetime totals, always showing the
/// player the next reward they're working toward.
enum MilestoneTrack { questsCompleted, goldEarned, heroLevel, itemsFound }

/// One rung of a track: cross [threshold] to unlock [rewardGold].
class MilestoneTier {
  final int threshold;
  final int rewardGold;
  const MilestoneTier(this.threshold, this.rewardGold);
}

/// A track and its ascending tiers, plus pure helpers for the next reward and
/// claimability given how many tiers are already claimed.
class MilestoneTrackDef {
  final MilestoneTrack track;
  final String title;
  final List<MilestoneTier> tiers;

  const MilestoneTrackDef({
    required this.track,
    required this.title,
    required this.tiers,
  });

  /// The next unclaimed tier (given [claimedCount] already-claimed tiers), or
  /// null once every tier is done.
  MilestoneTier? nextTier(int claimedCount) =>
      claimedCount >= 0 && claimedCount < tiers.length
          ? tiers[claimedCount]
          : null;

  /// Whether the player has reached the next tier but not yet claimed it.
  bool canClaim(int current, int claimedCount) {
    final next = nextTier(claimedCount);
    return next != null && current >= next.threshold;
  }
}

/// The fixed catalogue of milestone tracks.
class MilestoneCatalog {
  static const List<MilestoneTrackDef> tracks = [
    MilestoneTrackDef(
      track: MilestoneTrack.questsCompleted,
      title: 'Quests Completed',
      tiers: [
        MilestoneTier(10, 500),
        MilestoneTier(50, 1500),
        MilestoneTier(100, 3000),
        MilestoneTier(250, 7500),
        MilestoneTier(500, 15000),
        MilestoneTier(1000, 40000),
      ],
    ),
    MilestoneTrackDef(
      track: MilestoneTrack.goldEarned,
      title: 'Gold Earned',
      tiers: [
        MilestoneTier(1000, 250),
        MilestoneTier(10000, 2000),
        MilestoneTier(50000, 8000),
        MilestoneTier(100000, 15000),
        MilestoneTier(500000, 60000),
      ],
    ),
    MilestoneTrackDef(
      track: MilestoneTrack.heroLevel,
      title: 'Champion Level',
      tiers: [
        MilestoneTier(10, 1000),
        MilestoneTier(20, 3000),
        MilestoneTier(30, 6000),
        MilestoneTier(40, 12000),
        MilestoneTier(50, 25000),
      ],
    ),
    MilestoneTrackDef(
      track: MilestoneTrack.itemsFound,
      title: 'Items Found',
      tiers: [
        MilestoneTier(10, 500),
        MilestoneTier(50, 2000),
        MilestoneTier(100, 5000),
        MilestoneTier(250, 12000),
      ],
    ),
  ];

  static MilestoneTrackDef byTrack(MilestoneTrack t) =>
      tracks.firstWhere((d) => d.track == t);
}
