// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 3;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Customer(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      totalPurchases: fields[3] as double,
      paid: fields[4] as double,
      remaining: fields[5] as double,
      createdAt: fields[6] as DateTime,
      ledgerNumber: fields[7] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.totalPurchases)
      ..writeByte(4)
      ..write(obj.paid)
      ..writeByte(5)
      ..write(obj.remaining)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.ledgerNumber);
  }
}
