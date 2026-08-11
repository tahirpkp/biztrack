import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _uuid = const Uuid();
  String? _editingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _editingId == null) {
      _editingId = args;
      final box = Hive.box<Expense>('expenses');
      final e = box.get(_editingId);
      if (e != null) {
        _titleController.text = e.title;
        _categoryController.text = e.category;
        _amountController.text = e.amount.toString();
      }
    }
  }

  void _save() {
    // validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than 0')));
      return;
    }

    final id = _editingId ?? _uuid.v4();
    final exp = Expense(
      id: id,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      amount: amount,
      date: DateTime.now(),
    );
    Hive.box<Expense>('expenses').put(id, exp);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Expense')),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Expense Title')),
              TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: _amountController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
