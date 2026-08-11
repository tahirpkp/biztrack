import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class SaleDetail extends StatelessWidget {
  const SaleDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as String?;
    final salesBox = Hive.box<Sale>('sales');
    final customersBox = Hive.box<Customer>('customers');
    final sale = id != null ? salesBox.get(id) : null;
    final customer = sale != null ? customersBox.values.firstWhere((c) => c.name == sale.customerName, orElse: () => Customer(id: '', name: sale.customerName, phone: '', totalPurchases: 0.0, paid: 0.0, remaining: 0.0, createdAt: DateTime.now())) : null;

    if (sale == null) {
      return PopScopeCompat(
        onPop: () => handleWillPop(context),
        child: Scaffold(
          appBar: AppBar(title: const Text('Sale Detail')),
          drawer: const AppDrawer(),
          body: const Center(child: Text('Sale not found')),
        ),
      );
    }

    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sale Detail')),
        drawer: const AppDrawer(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(customer?.name ?? sale.customerName),
                      const SizedBox(height: 4),
                      Text('Phone: ${customer?.phone ?? '-'}'),
                      const SizedBox(height: 4),
                      Text('Sale date: ${sale.date.toLocal().toString().split('.').first}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Products', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...sale.products.map((product) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                Text('${product.quantity} x Rs. ${product.price.toStringAsFixed(2)}', textAlign: TextAlign.right),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Totals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total: Rs. ${sale.total.toStringAsFixed(2)}'),
                      Text('Payment: Rs. ${sale.payment.toStringAsFixed(2)}'),
                      Text('Balance: Rs. ${(sale.total - sale.payment).toStringAsFixed(2)}'),
                    ],
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
