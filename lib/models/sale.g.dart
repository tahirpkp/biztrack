// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 1;

  @override
  Sale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Sale(
      id: fields[0] as String,
      customerId: fields[1] as String,
      customerName: fields[2] as String,
      products: (fields[3] as List).cast<Product>(),
      total: fields[4] as double,
      payment: fields[5] as double,
      date: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.products)
      ..writeByte(4)
      ..write(obj.total)
      ..writeByte(5)
      ..write(obj.payment)
      ..writeByte(6)
      ..write(obj.date);
  }
}
