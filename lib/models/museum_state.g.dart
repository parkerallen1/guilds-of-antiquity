// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'museum_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MuseumStateAdapter extends TypeAdapter<MuseumState> {
  @override
  final int typeId = 8;

  @override
  MuseumState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MuseumState(
      unlockedItemIds: (fields[0] as List).cast<String>(),
      unlockedEndings: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MuseumState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.unlockedItemIds)
      ..writeByte(1)
      ..write(obj.unlockedEndings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuseumStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
