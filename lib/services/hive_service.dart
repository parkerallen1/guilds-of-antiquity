import 'package:hive_flutter/hive_flutter.dart';
import '../models/hero_model.dart';
import '../models/item_model.dart';
import '../models/quest_model.dart';
import '../models/log_entry_model.dart';

import '../models/museum_state.dart';

class HiveService {
  static const String heroBoxName = 'heroes';
  static const String questBoxName = 'quests';
  static const String logBoxName = 'logs';
  static const String settingsBoxName = 'settings';
  static const String inventoryBoxName = 'inventory';
  static const String vaultBoxName = 'vault';
  static const String museumBoxName = 'museum';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(HeroModelAdapter());
    Hive.registerAdapter(HeroStatusAdapter());
    Hive.registerAdapter(ItemAdapter());
    Hive.registerAdapter(ItemRarityAdapter());
    Hive.registerAdapter(ItemSlotAdapter());
    Hive.registerAdapter(QuestAdapter());
    Hive.registerAdapter(LogEntryAdapter());
    Hive.registerAdapter(LogTypeAdapter());
    Hive.registerAdapter(MuseumStateAdapter());

    await Hive.openBox<HeroModel>(heroBoxName);
    await Hive.openBox<Quest>(questBoxName);
    await Hive.openBox<LogEntry>(logBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<Item>(inventoryBoxName);
    await Hive.openBox<Item>(vaultBoxName);
    await Hive.openBox<MuseumState>(museumBoxName);
  }

  static Box<HeroModel> get heroesBox => Hive.box<HeroModel>(heroBoxName);
  static Box<Quest> get questsBox => Hive.box<Quest>(questBoxName);
  static Box<LogEntry> get logsBox => Hive.box<LogEntry>(logBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<Item> get inventoryBox => Hive.box<Item>(inventoryBoxName);
  static Box<Item> get vaultBox => Hive.box<Item>(vaultBoxName);
  static Box<MuseumState> get museumBox => Hive.box<MuseumState>(museumBoxName);
}
