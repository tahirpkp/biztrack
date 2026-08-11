import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class CustomerDetail extends StatefulWidget {
  const CustomerDetail({super.key});

  @override
  State<CustomerDetail> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<CustomerDetail> {
  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as String?;
    final customers = Hive.box<Customer>('customers');
    final sales = Hive.box<Sale>('sales');
    final customer = id != null ? customers.get(id) : null;
    final history = id != null ? sales.values.where((s) => s.customerId == customer?.id).toList().reversed.toList() : <Sale>[];

    if (customer == null) {
      return PopScopeCompat(onPop: () => handleWillPop(context), child: Scaffold(appBar: AppBar(title: const Text('Customer')), body: const Center(child: Text('Customer not found'))));
    }

    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: Text(customer.name)),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ledger #: ${customer.ledgerNumber.isEmpty ? '—' : customer.ledgerNumber}'),
              const SizedBox(height: 8),
              Text('Phone: ${customer.phone.isEmpty ? '—' : customer.phone}'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total Purchases: Rs. ${customer.totalPurchases.toStringAsFixed(2)}'),
                      Text('Paid: Rs. ${customer.paid.toStringAsFixed(2)}'),
                      Text('Remaining: Rs. ${customer.remaining.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final s = history[index];
                    return ListTile(
                      title: Text('${s.products.length} items'),
                      subtitle: Text('${s.date.toLocal()}'),
                      trailing: Text(s.total.toStringAsFixed(2)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
