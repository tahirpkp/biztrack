import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  Box<Expense> get expensesBox => Hive.box<Expense>('expenses');

  @override
  Widget build(BuildContext context) {
    final items = expensesBox.values.toList().reversed.toList();
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Expenses')),
        drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final e = items[index];
          return ListTile(
            title: Text(e.title),
            subtitle: Text(e.category),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  Navigator.pushNamed(context, '/add_expense', arguments: e.id).then((_) => setState(() {}));
                } else if (v == 'delete') {
                  final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Confirm'), content: const Text('Delete this expense?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes'))]));
                  if (confirm == true) {
                    await expensesBox.delete(e.id);
                    setState(() {});
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              child: Text('Rs. ${e.amount.toStringAsFixed(2)}'),
            ),
          );
        },
      ),
        floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_expense').then((_) => setState(() {})),
        child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
