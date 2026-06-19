// Unit tests for pure game logic. These run without a Flutter binding or Hive,
// so they're fast and reliable. (Replaces the default counter widget test,
// which tested a screen this app no longer has.)

import 'package:flutter_test/flutter_test.dart';
import 'package:guilds_of_antiquity/utils/loot_factory.dart';
import 'package:guilds_of_antiquity/models/item_model.dart';

void main() {
  group('LootFactory.generate', () {
    test('produces structurally valid items across many rolls', () {
      for (var i = 0; i < 500; i++) {
        final item = LootFactory.generate(10);
        expect(item.id, isNotEmpty);
        expect(item.name, isNotEmpty);
        expect(ItemRarity.values, contains(item.rarity));
        expect(ItemSlot.values, contains(item.slot));
        expect(item.value, greaterThanOrEqualTo(0));
        expect(item.strengthBonus, greaterThanOrEqualTo(0));
        expect(item.defenseBonus, greaterThanOrEqualTo(0));
        expect(item.bonusSpd, greaterThanOrEqualTo(0));
        expect(item.bonusLuck, greaterThanOrEqualTo(0));
      }
    });

    test('never drops a trophy-slot item as random loot', () {
      for (var i = 0; i < 300; i++) {
        expect(LootFactory.generate(5).slot, isNot(ItemSlot.trophy));
      }
    });

    test('a large rarityBonus eventually yields legendary drops', () {
      var legendaryCount = 0;
      for (var i = 0; i < 300; i++) {
        if (LootFactory.generate(10, rarityBonus: 40).rarity ==
            ItemRarity.legendary) {
          legendaryCount++;
        }
      }
      expect(legendaryCount, greaterThan(0));
    });

    test('higher item level yields higher stat budgets on average', () {
      int sumLow = 0, sumHigh = 0;
      for (var i = 0; i < 300; i++) {
        final low = LootFactory.generate(1);
        final high = LootFactory.generate(50);
        sumLow += low.strengthBonus + low.defenseBonus;
        sumHigh += high.strengthBonus + high.defenseBonus;
      }
      expect(sumHigh, greaterThan(sumLow));
    });
  });
}
