import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../models/receivable.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class SaleForm extends StatefulWidget {
  const SaleForm({super.key});

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> {
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ledgerController = TextEditingController();
  final _paymentController = TextEditingController();
  DateTime _date = DateTime.now();
  final _products = <Product>[];
  final _uuid = const Uuid();
  String? _editingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _editingId == null) {
      _editingId = args;
      final box = Hive.box<Sale>('sales');
      final sale = box.get(_editingId);
      if (sale != null) {
        _customerController.text = sale.customerName;
        _paymentController.text = sale.payment.toString();
        _date = sale.date;
        _products.clear();
        _products.addAll(sale.products.map((p) => Product(id: p.id, name: p.name, quantity: p.quantity, price: p.price, discount: p.discount)));
        final customers = Hive.box<Customer>('customers');
        for (var c in customers.values) {
          if (c.name.toLowerCase() == sale.customerName.toLowerCase()) {
            _phoneController.text = c.phone;
              _ledgerController.text = c.ledgerNumber;
            break;
          }
        }
      }
    }
  }

  void _addProductRow() {
    setState(() {
      _products.add(Product(id: _uuid.v4(), name: '', quantity: 1, price: 0.0));
    });
  }

  double get _total {
    double t = 0.0;
    for (var p in _products) {
      t += (p.price * p.quantity) - p.discount;
    }
    return t;
  }

  void _save() {
    if (_customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer name is required')));
      return;
    }
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one product')));
      return;
    }

    for (var p in _products) {
      if (p.name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name required')));
        return;
      }
      if (p.price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product price must be > 0')));
        return;
      }
    }

    final id = _editingId ?? _uuid.v4();
    final customerName = _customerController.text.trim();
    final phone = _phoneController.text.trim();
    final ledgerNumber = _ledgerController.text.trim();
    final payment = double.tryParse(_paymentController.text.trim()) ?? 0.0;
    final sales = Hive.box<Sale>('sales');
    final customers = Hive.box<Customer>('customers');
    final receivables = Hive.box<Receivable>('receivables');
    final oldSale = _editingId != null ? sales.get(_editingId) : null;

    Customer? existingCustomer;
    if (phone.isNotEmpty) {
      for (var c in customers.values) {
        if (c.phone == phone) {
          existingCustomer = c;
          break;
        }
      }
    }
    if (existingCustomer == null && ledgerNumber.isNotEmpty) {
      for (var c in customers.values) {
        if (c.ledgerNumber == ledgerNumber) {
          existingCustomer = c;
          break;
        }
      }
    }

    Customer? oldCustomer;
    if (oldSale != null) {
      oldCustomer = customers.get(oldSale.customerId);
      if (oldCustomer != null) {
        oldCustomer.totalPurchases -= oldSale.total;
        oldCustomer.paid -= oldSale.payment;
        oldCustomer.remaining = oldCustomer.totalPurchases - oldCustomer.paid;
        customers.put(oldCustomer.id, oldCustomer);
      }
    }

    final customerId = existingCustomer?.id ?? _uuid.v4();
    final updatedCustomer = existingCustomer != null
        ? Customer(
            id: customerId,
            name: customerName,
            phone: phone.isNotEmpty ? phone : existingCustomer.phone,
            ledgerNumber: ledgerNumber.isNotEmpty ? ledgerNumber : existingCustomer.ledgerNumber,
            totalPurchases: existingCustomer.totalPurchases + _total,
            paid: existingCustomer.paid + payment,
            remaining: existingCustomer.remaining + (_total - payment),
            createdAt: existingCustomer.createdAt,
          )
        : Customer(
            id: customerId,
            name: customerName,
            phone: phone,
            ledgerNumber: ledgerNumber,
            totalPurchases: _total,
            paid: payment,
            remaining: _total - payment,
            createdAt: DateTime.now(),
          );

    final sale = Sale(
      id: id,
      customerId: customerId,
      customerName: customerName,
      products: List.from(_products),
      total: _total,
      payment: payment,
      date: _date,
    );

    sales.put(id, sale);
    customers.put(customerId, updatedCustomer);

    if (payment < _total) {
      final receivable = Receivable(
        id: id,
        customerId: customerId,
        amount: _total,
        paid: payment,
        remaining: _total - payment,
        createdAt: DateTime.now(),
      );
      receivables.put(id, receivable);
    } else {
      if (receivables.containsKey(id)) {
        receivables.delete(id);
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Sale')),
        drawer: const AppDrawer(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha((0.08 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Sale', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Create a sale quickly with customer info, products and payment details.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Customer Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Customer Phone (optional)', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ledgerController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Ledger Number (optional)', prefixIcon: Icon(Icons.receipt_long)),
              ),
              const SizedBox(height: 20),
              Text('Products', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._products.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Item ${i + 1}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(() => _products.removeAt(i)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (v) => p.name = v,
                          decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.inventory_2)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (v) => p.quantity = int.tryParse(v) ?? 1,
                                decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.format_list_numbered)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (v) => p.price = double.tryParse(v) ?? 0.0,
                                decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => p.discount = double.tryParse(v) ?? 0.0,
                          decoration: const InputDecoration(labelText: 'Discount', prefixIcon: Icon(Icons.percent)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addProductRow,
                icon: const Icon(Icons.add),
                label: const Text('Add product'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Order Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: Theme.of(context).textTheme.bodyLarge),
                        Text('Rs. ${_total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _paymentController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Payment', prefixIcon: Icon(Icons.payment)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Remaining', style: Theme.of(context).textTheme.bodyLarge),
                        Text('Rs. ${( _total - (double.tryParse(_paymentController.text.trim()) ?? 0.0)).toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text('Save Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size.fromHeight(54),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
