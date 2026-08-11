import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sale.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class SalesList extends StatefulWidget {
  const SalesList({super.key});

  @override
  State<SalesList> createState() => _SalesListState();
}

class _SalesListState extends State<SalesList> {
  Box<Sale> get salesBox => Hive.box<Sale>('sales');

  @override
  Widget build(BuildContext context) {
    final sales = salesBox.values.toList().reversed.toList();
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sales')),
        drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final s = sales[index];
          return ListTile(
            title: Text(s.customerName),
            subtitle: Text('${s.products.length} items • ${s.date.toLocal()}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  Navigator.pushNamed(context, '/add_sale', arguments: s.id).then((_) => setState(() {}));
                } else if (v == 'delete') {
                  final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Confirm'), content: const Text('Delete this sale?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes'))]));
                  if (confirm == true) {
                    await salesBox.delete(s.id);
                    setState(() {});
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              child: Text(s.total.toStringAsFixed(2)),
            ),
          );
        },
      ),
        floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_sale').then((_) => setState(() {})),
        child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
