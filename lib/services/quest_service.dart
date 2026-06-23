import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/quest_model.dart';
import 'hive_service.dart';

class QuestService {
  List<Quest> _allQuests = [];
  bool _isLoaded = false;

  Future<void> loadQuests() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/quests.json',
      );
      final dynamic jsonData = json.decode(jsonString);
      List<dynamic> jsonList;

      if (jsonData is Map) {
        // New format with metadata
        jsonList = jsonData['quests'] as List<dynamic>;
      } else {
        // Old format (List)
        jsonList = jsonData as List<dynamic>;
      }

      _allQuests = jsonList.map((json) => Quest.fromJson(json)).toList();
      _isLoaded = true;
    } catch (e) {
      debugPrint("Error loading quests: $e");
      // Fallback or rethrow
    }
  }

  List<Quest> getMainQuests() {
    return _allQuests.where((q) => q.isMainQuest).toList();
  }

  List<Quest> getSideQuests() {
    return _allQuests.where((q) => !q.isMainQuest).toList();
  }

  Quest? getQuestById(String id) {
    for (final q in _allQuests) {
      if (q.id == id) return q;
    }
    // Dynamically-generated quests (lodge scouting + daily bounties) live in
    // the Hive quest box, not the bundled asset list. Without this fallback
    // they couldn't be resolved by the UI or the ticker once discovered.
    return HiveService.questsBox.get(id);
  }

  List<Quest> getRandomSideQuests(int count) {
    final sideQuests = getSideQuests();
    if (sideQuests.isEmpty) return [];

    final random = Random();
    final List<Quest> selected = [];
    final List<Quest> available = List.from(sideQuests);

    for (int i = 0; i < count; i++) {
      if (available.isEmpty) break;
      final index = random.nextInt(available.length);
      selected.add(available[index]);
      available.removeAt(index);
    }
    return selected;
  }
}
