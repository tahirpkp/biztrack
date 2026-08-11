import 'package:hive/hive.dart';

part 'receivable.g.dart';

@HiveType(typeId: 4)
class Receivable {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  double paid;

  @HiveField(4)
  double remaining;

  @HiveField(5)
  DateTime createdAt;

  Receivable({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paid,
    required this.remaining,
    required this.createdAt,
  });
}
