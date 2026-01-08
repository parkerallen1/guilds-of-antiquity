// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogEntryAdapter extends TypeAdapter<LogEntry> {
  @override
  final int typeId = 5;

  @override
  LogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogEntry(
      message: fields[0] as String,
      type: fields[1] as LogType,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LogEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.message)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogTypeAdapter extends TypeAdapter<LogType> {
  @override
  final int typeId = 4;

  @override
  LogType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogType.info;
      case 1:
        return LogType.combat;
      case 2:
        return LogType.loot;
      case 3:
        return LogType.gold;
      default:
        return LogType.info;
    }
  }

  @override
  void write(BinaryWriter writer, LogType obj) {
    switch (obj) {
      case LogType.info:
        writer.writeByte(0);
        break;
      case LogType.combat:
        writer.writeByte(1);
        break;
      case LogType.loot:
        writer.writeByte(2);
        break;
      case LogType.gold:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
