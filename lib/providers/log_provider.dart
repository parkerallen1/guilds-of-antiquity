import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_entry_model.dart';
import '../services/hive_service.dart';

final logProvider = StateNotifierProvider<LogNotifier, List<LogEntry>>((ref) {
  return LogNotifier();
});

class LogNotifier extends StateNotifier<List<LogEntry>> {
  LogNotifier() : super([]) {
    _loadLogs();
  }

  void _loadLogs() {
    final box = HiveService.logsBox;
    state = box.values.toList().reversed.toList();
  }

  void addLog(String message, LogType type) {
    final entry = LogEntry(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    HiveService.logsBox.add(entry);
    state = [entry, ...state];
  }
  
  void clearLogs() {
    HiveService.logsBox.clear();
    state = [];
  }
}
