import 'dart:convert';
import 'dart:io';

import '../../lib/models/quest_model.dart';

/// Loads the REAL quest data from `assets/data/quests.json` and answers the
/// availability questions the live game answers (prerequisite + hint gating).
class QuestRepo {
  final List<Quest> all;
  final Map<String, Quest> _byId;

  QuestRepo(this.all) : _byId = {for (final q in all) q.id: q};

  static QuestRepo load({String? explicitPath}) {
    final path = explicitPath ?? _findQuestsJson();
    final raw = File(path).readAsStringSync();
    final data = json.decode(raw);
    final list = (data is Map ? data['quests'] : data) as List<dynamic>;
    final quests = list
        .map((j) => Quest.fromJson(j as Map<String, dynamic>))
        .toList();
    return QuestRepo(quests);
  }

  /// Walk up from cwd and from this file's directory looking for the asset.
  static String _findQuestsJson() {
    final candidates = <Directory>[
      Directory.current,
      File(Platform.script.toFilePath()).parent, // sim/bin
    ];
    for (var dir in candidates) {
      var d = dir;
      for (int i = 0; i < 6; i++) {
        final f = File('${d.path}/assets/data/quests.json');
        if (f.existsSync()) return f.path;
        final parent = d.parent;
        if (parent.path == d.path) break;
        d = parent;
      }
    }
    throw StateError(
      'Could not locate assets/data/quests.json — pass an explicit path.',
    );
  }

  Quest? byId(String id) => _byId[id];

  List<Quest> get mainQuests => all.where((q) => q.isMainQuest).toList();
  List<Quest> get sideQuests => all.where((q) => !q.isMainQuest).toList();

  /// Hidden quests (requiredHints > 0) that still need more hints. This mirrors
  /// `_buyShard` eligibility exactly: prerequisite completion is NOT required,
  /// so shards can be "wasted" on a hidden quest you don't currently want.
  List<Quest> hintEligible(Map<String, int> hints) => all
      .where((q) => q.requiredHints > 0 && (hints[q.id] ?? 0) < q.requiredHints)
      .toList();

  bool hintsSatisfied(Quest q, Map<String, int> hints) =>
      q.requiredHints == 0 || (hints[q.id] ?? 0) >= q.requiredHints;

  bool prereqSatisfied(Quest q, Set<String> completed) =>
      q.requiredQuestId == null || completed.contains(q.requiredQuestId);
}
