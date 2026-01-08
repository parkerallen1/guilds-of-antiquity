import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/hero_model.dart';
import '../services/hive_service.dart';
import '../utils/text_gen.dart';
import 'game_provider.dart';

final heroProvider = StateNotifierProvider<HeroNotifier, List<HeroModel>>((
  ref,
) {
  return HeroNotifier(ref);
});

class HeroNotifier extends StateNotifier<List<HeroModel>> {
  final Ref ref;

  HeroNotifier(this.ref) : super([]) {
    _loadHeroes();
  }

  void _loadHeroes() {
    final box = HiveService.heroesBox;
    state = box.values.toList();
  }

  void addHero(HeroModel hero) {
    HiveService.heroesBox.add(hero);
    state = [...state, hero];
  }

  void recruitHero() {
    final gameState = ref.read(gameProvider);

    // Era 0 Limit: 1 Hero
    if (gameState.currentEraIndex == 0 && state.isNotEmpty) {
      return;
    }

    if (state.length >= 5) return; // Hard Roster limit

    const cost = 50;
    final gameNotifier = ref.read(gameProvider.notifier);

    if (gameState.gold >= cost) {
      gameNotifier.spendGold(cost);

      final newHero = HeroModel(
        id: const Uuid().v4(),
        name: TextGen.generateHeroName(),
        classType: "Mercenary",
        strength: 5, // Base stats
        speed: 5,
        hp: 100,
        maxHp: 100,
      );

      HiveService.heroesBox.add(newHero);
      state = [...state, newHero];
    }
  }

  void dismissHero(HeroModel hero) {
    final box = HiveService.heroesBox;

    // Find the key for this hero in the box
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.id == hero.id,
      orElse: () => null,
    );

    if (key != null) {
      box.delete(key);
      state = state.where((h) => h.id != hero.id).toList();
    }
  }

  void updateHero(HeroModel hero) {
    // Hive objects are stored by key (usually auto-incrementing int if using add, or dynamic key if using put)
    // Since we used add(), we might need to find the key.
    // However, for simplicity in this MVP, we can just save the object if it extends HiveObject.
    // But our model doesn't extend HiveObject. Let's find the key.

    final box = HiveService.heroesBox;
    final key = box.keyAt(state.indexWhere((h) => h.id == hero.id));
    box.put(key, hero);

    state = [
      for (final h in state)
        if (h.id == hero.id) hero else h,
    ];
  }
}
