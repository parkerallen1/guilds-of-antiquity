// Unit tests for the pure Ancient-Coin meta-upgrade math. No Flutter / Hive.

import 'package:flutter_test/flutter_test.dart';
import 'package:guilds_of_antiquity/models/meta_upgrade.dart';

void main() {
  group('MetaUpgradeDef.costAt', () {
    final greed = MetaUpgradeCatalog.of(MetaUpgrade.greed);

    test('first level costs the base cost', () {
      expect(greed.costAt(0), greed.baseCost);
    });

    test('cost grows with level', () {
      expect(greed.costAt(2), greaterThan(greed.costAt(1)!));
    });

    test('returns null once maxed', () {
      expect(greed.costAt(greed.maxLevel), isNull);
    });
  });

  group('MetaUpgradeDef.valueAt', () {
    test('scales linearly per level from zero', () {
      final scholar = MetaUpgradeCatalog.of(MetaUpgrade.scholar);
      expect(scholar.valueAt(0), 0.0);
      expect(scholar.valueAt(5), closeTo(scholar.perLevel * 5, 1e-9));
    });

    test('effect label renders a percentage', () {
      final greed = MetaUpgradeCatalog.of(MetaUpgrade.greed);
      expect(greed.effectLabel(4), contains('%'));
      expect(greed.effectLabel(4), contains('gold gain'));
    });
  });

  test('catalogue covers every upgrade enum', () {
    for (final u in MetaUpgrade.values) {
      expect(MetaUpgradeCatalog.of(u).type, u);
    }
    expect(MetaUpgradeCatalog.all.length, MetaUpgrade.values.length);
  });
}
