import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> _getNotesFilePath() async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/debug_notes.txt';
}

Future<String> readNotes() async {
  try {
    final path = await _getNotesFilePath();
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  } catch (e) {
    // If any error occurs, return empty string
    return '';
  }
}

Future<void> writeNotes(String content) async {
  final path = await _getNotesFilePath();
  final file = File(path);
  await file.writeAsString(content);
}
