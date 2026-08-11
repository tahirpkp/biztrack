import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/receivable.dart';
import '../models/customer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class ReceivablesList extends StatefulWidget {
  const ReceivablesList({super.key});

  @override
  State<ReceivablesList> createState() => _ReceivablesListState();
}

class _ReceivablesListState extends State<ReceivablesList> {
  Box<Receivable> get box => Hive.box<Receivable>('receivables');

  @override
  Widget build(BuildContext context) {
    final customers = Hive.box<Customer>('customers');
    final items = box.values.toList().reversed.toList();
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Receivables')),
        drawer: const AppDrawer(),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final r = items[index];
            final customer = customers.get(r.customerId);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(customer?.name ?? r.customerId, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Text('Rs. ${r.remaining.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Customer remaining: Rs. ${customer?.remaining.toStringAsFixed(2) ?? 'N/A'}'),
                    const SizedBox(height: 4),
                    Text(r.createdAt.toLocal().toString().split('.').first),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/receivable_payment', arguments: r.id).then((_) => setState(() {})),
                          icon: const Icon(Icons.payments),
                          label: const Text('Pay'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Receivable'),
                                content: const Text('Remove this receivable record? This will not affect the sale record.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await box.delete(r.id);
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
