import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 3)
class Customer {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  double totalPurchases;

  @HiveField(4)
  double paid;

  @HiveField(5)
  double remaining;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String ledgerNumber;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.totalPurchases = 0.0,
    this.paid = 0.0,
    this.remaining = 0.0,
    required this.createdAt,
    this.ledgerNumber = '',
  });
}
