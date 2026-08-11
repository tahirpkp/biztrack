import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  double price;

  @HiveField(4)
  double discount;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
  });
}
