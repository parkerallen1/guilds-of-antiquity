import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quest_service.dart';

final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService();
});

final questLoaderProvider = FutureProvider<void>((ref) async {
  final service = ref.read(questServiceProvider);
  await service.loadQuests();
});

class QuestResult {
  final bool success;
  final int goldGained;
  final int xpGained;
  final List<String> itemsGained;
  final String questTitle;
  final String heroId;
  final DateTime timestamp;

  QuestResult({
    required this.success,
    required this.goldGained,
    required this.xpGained,
    required this.itemsGained,
    required this.questTitle,
    required this.heroId,
    required this.timestamp,
  });
}

final questResultProvider = StateProvider<Map<String, QuestResult>>(
  (ref) => {},
);
