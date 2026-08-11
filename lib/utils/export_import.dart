import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';

import '../models/customer.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../models/receivable.dart';
import '../models/sale.dart';
import 'backup_model.dart';

const _backupType = 'biztrack.backup';
const _backupSchemaVersion = 1;

Map<String, dynamic> _salesToJson(Sale s) => {
      'id': s.id,
      'customerId': s.customerId,
      'customerName': s.customerName,
      'products': s.products
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'quantity': p.quantity,
                'price': p.price,
                'discount': p.discount,
              })
          .toList(),
      'total': s.total,
      'payment': s.payment,
      'date': s.date.toIso8601String(),
    };

Map<String, dynamic> _expenseToJson(Expense e) => {
      'id': e.id,
      'title': e.title,
      'category': e.category,
      'amount': e.amount,
      'date': e.date.toIso8601String(),
    };

Map<String, dynamic> _customerToJson(Customer c) => {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'totalPurchases': c.totalPurchases,
      'paid': c.paid,
      'remaining': c.remaining,
      'createdAt': c.createdAt.toIso8601String(),
      'ledgerNumber': c.ledgerNumber,
    };

Map<String, dynamic> _receivableToJson(Receivable r) => {
      'id': r.id,
      'customerId': r.customerId,
      'amount': r.amount,
      'paid': r.paid,
      'remaining': r.remaining,
      'createdAt': r.createdAt.toIso8601String(),
    };

Future<void> exportBackup(String filePath) async {
  final salesBox = Hive.box<Sale>('sales');
  final expensesBox = Hive.box<Expense>('expenses');
  final customersBox = Hive.box<Customer>('customers');
  final receivablesBox = Hive.box<Receivable>('receivables');
  final settingsBox = Hive.box('settings');
  final productsBox = Hive.box<Product>('products');

  final data = {
    'metadata': {
      'backupType': _backupType,
      'schemaVersion': _backupSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'recordCounts': {
        'settings': settingsBox.length,
        'products': productsBox.length,
        'customers': customersBox.length,
        'sales': salesBox.length,
        'expenses': expensesBox.length,
        'receivables': receivablesBox.length,
      },
    },
    'records': {
      'settings': settingsBox.toMap().cast<String, dynamic>(),
      'products': productsBox.values.map((p) => {
            'id': p.id,
            'name': p.name,
            'quantity': p.quantity,
            'price': p.price,
            'discount': p.discount,
          }).toList(),
      'customers': customersBox.values.map(_customerToJson).toList(),
      'sales': salesBox.values.map(_salesToJson).toList(),
      'expenses': expensesBox.values.map(_expenseToJson).toList(),
      'receivables': receivablesBox.values.map(_receivableToJson).toList(),
    },
  };

  final encoded = jsonEncode(data);
  final file = File(filePath);
  await file.writeAsString(encoded, flush: true);
}

Future<BackupPreview> previewBackup(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    return BackupPreview(
      isValid: false,
      errorMessage: 'Backup file not found',
      schemaVersion: 0,
      appVersion: null,
      recordCounts: {},
      duplicateCounts: {},
      missingBoxes: [],
    );
  }

  try {
    final content = await file.readAsString();
    final jsonMap = jsonDecode(content);
    if (jsonMap is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup structure');
    }

    final metadata = jsonMap['metadata'];
    if (metadata is! Map<String, dynamic>) {
      throw const FormatException('Missing metadata');
    }

    final backupType = metadata['backupType'];
    if (backupType != _backupType) {
      throw const FormatException('Invalid backup file type');
    }

    final schemaVersion = metadata['schemaVersion'];
    if (schemaVersion is! int) {
      throw const FormatException('Invalid schema version');
    }

    final records = jsonMap['records'];
    if (records is! Map<String, dynamic>) {
      throw const FormatException('Missing records');
    }

    final recordCounts = <String, int>{};
    final missingBoxes = <String>[];
    final duplicateCounts = <String, int>{};

    final settings = records['settings'];
    final products = records['products'];
    final customers = records['customers'];
    final sales = records['sales'];
    final expenses = records['expenses'];
    final receivables = records['receivables'];

    if (settings is Map<String, dynamic>) {
      recordCounts['settings'] = settings.length;
      duplicateCounts['settings'] = _countDuplicateKeys(settings, Hive.box('settings').toMap());
    } else {
      missingBoxes.add('settings');
    }

    if (products is List) {
      recordCounts['products'] = products.length;
      duplicateCounts['products'] = _countDuplicateIds(products, 'id', Hive.box<Product>('products').keys.cast<String>().toSet());
    } else {
      missingBoxes.add('products');
    }

    if (customers is List) {
      recordCounts['customers'] = customers.length;
      duplicateCounts['customers'] = _countDuplicateIds(customers, 'id', Hive.box<Customer>('customers').keys.cast<String>().toSet());
    } else {
      missingBoxes.add('customers');
    }

    if (sales is List) {
      recordCounts['sales'] = sales.length;
      duplicateCounts['sales'] = _countDuplicateIds(sales, 'id', Hive.box<Sale>('sales').keys.cast<String>().toSet());
    } else {
      missingBoxes.add('sales');
    }

    if (expenses is List) {
      recordCounts['expenses'] = expenses.length;
      duplicateCounts['expenses'] = _countDuplicateIds(expenses, 'id', Hive.box<Expense>('expenses').keys.cast<String>().toSet());
    } else {
      missingBoxes.add('expenses');
    }

    if (receivables is List) {
      recordCounts['receivables'] = receivables.length;
      duplicateCounts['receivables'] = _countDuplicateIds(receivables, 'id', Hive.box<Receivable>('receivables').keys.cast<String>().toSet());
    } else {
      missingBoxes.add('receivables');
    }

    return BackupPreview(
      isValid: true,
      schemaVersion: schemaVersion,
      appVersion: metadata['appVersion'] as String?,
      recordCounts: recordCounts,
      duplicateCounts: duplicateCounts,
      missingBoxes: missingBoxes,
    );
  } catch (e) {
    return BackupPreview(
      isValid: false,
      errorMessage: e.toString(),
      schemaVersion: 0,
      appVersion: null,
      recordCounts: {},
      duplicateCounts: {},
      missingBoxes: [],
    );
  }
}

int _countDuplicateKeys(Map<String, dynamic> incoming, Map existing) {
  return incoming.keys.where((key) => existing.containsKey(key)).length;
}

int _countDuplicateIds(List<dynamic> incoming, String idKey, Set<String> existingIds) {
  return incoming.where((item) => item is Map<String, dynamic> && item[idKey] is String && existingIds.contains(item[idKey] as String)).length;
}

Future<void> restoreBackup(String filePath, {required bool overwrite}) async {
  final preview = await previewBackup(filePath);
  if (!preview.isValid) {
    throw Exception(preview.errorMessage ?? 'Backup validation failed');
  }
  if (preview.schemaVersion != _backupSchemaVersion) {
    throw Exception('Backup schema version ${preview.schemaVersion} is not supported. Expected $_backupSchemaVersion.');
  }

  final file = File(filePath);
  final content = await file.readAsString();
  final jsonMap = jsonDecode(content) as Map<String, dynamic>;
  final records = jsonMap['records'] as Map<String, dynamic>;

  final salesBox = Hive.box<Sale>('sales');
  final expensesBox = Hive.box<Expense>('expenses');
  final customersBox = Hive.box<Customer>('customers');
  final receivablesBox = Hive.box<Receivable>('receivables');
  final settingsBox = Hive.box('settings');
  final productsBox = Hive.box<Product>('products');

  if (overwrite) {
    await salesBox.clear();
    await expensesBox.clear();
    await customersBox.clear();
    await receivablesBox.clear();
    await settingsBox.clear();
    await productsBox.clear();
  }

  if (records['settings'] is Map<String, dynamic>) {
    final settings = records['settings'] as Map<String, dynamic>;
    for (final entry in settings.entries) {
      if (overwrite || !settingsBox.containsKey(entry.key)) {
        settingsBox.put(entry.key, entry.value);
      }
    }
  }

  if (records['products'] is List) {
    for (final item in records['products'] as List) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String;
        if (overwrite || !productsBox.containsKey(id)) {
          productsBox.put(
            id,
            Product(
              id: id,
              name: item['name'] ?? '',
              quantity: (item['quantity'] as num?)?.toInt() ?? 0,
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              discount: (item['discount'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }
    }
  }

  if (records['customers'] is List) {
    for (final item in records['customers'] as List) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String;
        if (overwrite || !customersBox.containsKey(id)) {
          customersBox.put(
            id,
            Customer(
              id: id,
              name: item['name'] ?? '',
              phone: item['phone'] ?? '',
              totalPurchases: (item['totalPurchases'] as num?)?.toDouble() ?? 0.0,
              paid: (item['paid'] as num?)?.toDouble() ?? 0.0,
              remaining: (item['remaining'] as num?)?.toDouble() ?? 0.0,
              createdAt: DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String()),
              ledgerNumber: item['ledgerNumber'] ?? '',
            ),
          );
        }
      }
    }
  }

  if (records['sales'] is List) {
    for (final item in records['sales'] as List) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String;
        if (overwrite || !salesBox.containsKey(id)) {
          final products = (item['products'] as List).map((p) {
            return Product(
              id: p['id'],
              name: p['name'],
              quantity: p['quantity'],
              price: (p['price'] as num).toDouble(),
              discount: (p['discount'] as num).toDouble(),
            );
          }).toList();
          salesBox.put(
            id,
            Sale(
              id: id,
              customerId: item['customerId'],
              customerName: item['customerName'],
              products: products,
              total: (item['total'] as num).toDouble(),
              payment: (item['payment'] as num).toDouble(),
              date: DateTime.parse(item['date']),
            ),
          );
        }
      }
    }
  }

  if (records['expenses'] is List) {
    for (final item in records['expenses'] as List) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String;
        if (overwrite || !expensesBox.containsKey(id)) {
          expensesBox.put(
            id,
            Expense(
              id: id,
              title: item['title'],
              category: item['category'],
              amount: (item['amount'] as num).toDouble(),
              date: DateTime.parse(item['date']),
            ),
          );
        }
      }
    }
  }

  if (records['receivables'] is List) {
    for (final item in records['receivables'] as List) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String;
        if (overwrite || !receivablesBox.containsKey(id)) {
          receivablesBox.put(
            id,
            Receivable(
              id: id,
              customerId: item['customerId'],
              amount: (item['amount'] as num).toDouble(),
              paid: (item['paid'] as num).toDouble(),
              remaining: (item['remaining'] as num).toDouble(),
              createdAt: DateTime.parse(item['createdAt']),
            ),
          );
        }
      }
    }
  }
}
