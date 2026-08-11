import 'package:hive/hive.dart';
import 'product.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class Sale {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String customerName;

  @HiveField(3)
  List<Product> products;

  @HiveField(4)
  double total;

  @HiveField(5)
  double payment;

  @HiveField(6)
  DateTime date;

  Sale({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.products,
    required this.total,
    required this.payment,
    required this.date,
  });
}
