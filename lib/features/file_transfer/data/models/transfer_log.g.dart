// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferLogAdapter extends TypeAdapter<TransferLog> {
  @override
  final int typeId = 0;

  @override
  TransferLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransferLog(
      id: fields[0] as String,
      fileName: fields[1] as String,
      filePath: fields[2] as String,
      fileSize: fields[3] as int,
      fileType: fields[4] as FileCategory,
      timestamp: fields[5] as DateTime,
      direction: fields[6] as TransferDirection,
      status: fields[7] as TransferStatus,
    );
  }

  @override
  void write(BinaryWriter writer, TransferLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.fileSize)
      ..writeByte(4)
      ..write(obj.fileType)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.direction)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FileCategoryAdapter extends TypeAdapter<FileCategory> {
  @override
  final int typeId = 1;

  @override
  FileCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FileCategory.image;
      case 1:
        return FileCategory.video;
      case 2:
        return FileCategory.document;
      case 3:
        return FileCategory.archive;
      case 4:
        return FileCategory.audio;
      case 5:
        return FileCategory.other;
      default:
        return FileCategory.other;
    }
  }

  @override
  void write(BinaryWriter writer, FileCategory obj) {
    switch (obj) {
      case FileCategory.image:
        writer.writeByte(0);
        break;
      case FileCategory.video:
        writer.writeByte(1);
        break;
      case FileCategory.document:
        writer.writeByte(2);
        break;
      case FileCategory.archive:
        writer.writeByte(3);
        break;
      case FileCategory.audio:
        writer.writeByte(4);
        break;
      case FileCategory.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransferDirectionAdapter extends TypeAdapter<TransferDirection> {
  @override
  final int typeId = 2;

  @override
  TransferDirection read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransferDirection.sent;
      case 1:
        return TransferDirection.received;
      default:
        return TransferDirection.received;
    }
  }

  @override
  void write(BinaryWriter writer, TransferDirection obj) {
    switch (obj) {
      case TransferDirection.sent:
        writer.writeByte(0);
        break;
      case TransferDirection.received:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferDirectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransferStatusAdapter extends TypeAdapter<TransferStatus> {
  @override
  final int typeId = 3;

  @override
  TransferStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransferStatus.completed;
      case 1:
        return TransferStatus.failed;
      case 2:
        return TransferStatus.inProgress;
      default:
        return TransferStatus.completed;
    }
  }

  @override
  void write(BinaryWriter writer, TransferStatus obj) {
    switch (obj) {
      case TransferStatus.completed:
        writer.writeByte(0);
        break;
      case TransferStatus.failed:
        writer.writeByte(1);
        break;
      case TransferStatus.inProgress:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
