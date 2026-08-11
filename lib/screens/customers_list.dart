import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../utils/whatsapp_helper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class CustomersList extends StatefulWidget {
  const CustomersList({super.key});

  @override
  State<CustomersList> createState() => _CustomersListState();
}

class _CustomersListState extends State<CustomersList> {
  Box<Customer> get customersBox => Hive.box<Customer>('customers');
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allCustomers = customersBox.values.toList().reversed.toList();
    final customers = _query.isEmpty
        ? allCustomers
        : allCustomers.where((c) {
            final normalized = _query.toLowerCase();
            return c.name.toLowerCase().contains(normalized)
                || c.phone.toLowerCase().contains(normalized)
                || c.ledgerNumber.toLowerCase().contains(normalized);
          }).toList();
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Customers')),
        drawer: const AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name, phone, or ledger',
                filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 44, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.4 * 255).round())),
                          const SizedBox(height: 14),
                          Text('No customers found', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Add a customer to start tracking sales and balances.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(c.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                  Text('Rs. ${c.remaining.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(c.phone.isEmpty ? 'Phone: —' : 'Phone: ${c.phone}', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: c.phone.isNotEmpty
                                          ? () => openWhatsApp(
                                                rawPhone: c.phone,
                                                message: c.remaining > 0
                                                    ? 'محترم ${c.name}, آپ کے ذمہ Rs. ${c.remaining.toStringAsFixed(2)} ہیں۔ براہ کرم جلد ادا کریں۔'
                                                    : 'محترم ${c.name}, آپ کا بقایا صفر ہے۔ اگر آپ کو کوئی سوال ہو تو براہ کرم مطلع کریں۔',
                                              )
                                          : null,
                                      icon: const Icon(Icons.message, size: 20),
                                      label: const Text('Message'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                        minimumSize: const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 22),
                                    onPressed: () => Navigator.pushNamed(context, '/add_customer', arguments: c.id).then((_) => setState(() {})),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 22),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete customer'),
                                          content: const Text('Are you sure you want to delete this customer?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await customersBox.delete(c.id);
                                        setState(() {});
                                      }
                                    },
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
        ],
      ),
        floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_customer').then((_) => setState(() {})),
        child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
