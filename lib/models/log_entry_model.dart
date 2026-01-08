import 'package:hive/hive.dart';

part 'log_entry_model.g.dart';

@HiveType(typeId: 4)
enum LogType {
  @HiveField(0)
  info,
  @HiveField(1)
  combat,
  @HiveField(2)
  loot,
  @HiveField(3)
  gold,
}

@HiveType(typeId: 5)
class LogEntry {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final LogType type;

  @HiveField(2)
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}
