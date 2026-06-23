// Unit tests for the pure milestone tier logic. No Flutter binding / Hive.

import 'package:flutter_test/flutter_test.dart';
import 'package:guilds_of_antiquity/models/milestone.dart';

void main() {
  final quests = MilestoneCatalog.byTrack(MilestoneTrack.questsCompleted);

  group('MilestoneTrackDef.nextTier', () {
    test('returns the tier at the claimed index', () {
      expect(quests.nextTier(0)!.threshold, 10);
      expect(quests.nextTier(1)!.threshold, 50);
    });

    test('returns null once all tiers are claimed', () {
      expect(quests.nextTier(quests.tiers.length), isNull);
    });
  });

  group('MilestoneTrackDef.canClaim', () {
    test('false before the next threshold is reached', () {
      expect(quests.canClaim(9, 0), isFalse);
    });

    test('true once the next threshold is reached and unclaimed', () {
      expect(quests.canClaim(10, 0), isTrue);
      expect(quests.canClaim(60, 1), isTrue);
    });

    test('false when every tier is already claimed', () {
      expect(quests.canClaim(99999, quests.tiers.length), isFalse);
    });
  });

  test('catalogue tiers ascend in both threshold and reward', () {
    for (final def in MilestoneCatalog.tracks) {
      for (int i = 1; i < def.tiers.length; i++) {
        expect(def.tiers[i].threshold, greaterThan(def.tiers[i - 1].threshold));
        expect(def.tiers[i].rewardGold,
            greaterThan(def.tiers[i - 1].rewardGold));
      }
    }
  });
}
