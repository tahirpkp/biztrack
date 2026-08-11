import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ledgerController = TextEditingController();
  final _uuid = const Uuid();
  String? _editingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _editingId == null) {
      _editingId = args;
      final box = Hive.box<Customer>('customers');
      final c = box.get(_editingId);
      if (c != null) {
        _nameController.text = c.name;
        _phoneController.text = c.phone;
        _ledgerController.text = c.ledgerNumber;
      }
    }
  }

  void _save() {
    // validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer name is required')));
      return;
    }

    final id = _editingId ?? _uuid.v4();
    final cust = Customer(
      id: id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      ledgerNumber: _ledgerController.text.trim(),
      createdAt: DateTime.now(),
    );
    Hive.box<Customer>('customers').put(id, cust);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Customer')),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
              const SizedBox(height: 12),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
                const SizedBox(height: 12),
                TextField(controller: _ledgerController, keyboardType: TextInputType.text, decoration: const InputDecoration(labelText: 'Ledger Number (optional)')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
