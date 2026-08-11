// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receivable.dart';

class ReceivableAdapter extends TypeAdapter<Receivable> {
  @override
  final int typeId = 4;

  @override
  Receivable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Receivable(
      id: fields[0] as String,
      customerId: fields[1] as String,
      amount: fields[2] as double,
      paid: fields[3] as double,
      remaining: fields[4] as double,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Receivable obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paid)
      ..writeByte(4)
      ..write(obj.remaining)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}
