import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/receivable.dart';
import '../models/customer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class ReceivablePayment extends StatefulWidget {
  const ReceivablePayment({super.key});

  @override
  State<ReceivablePayment> createState() => _ReceivablePaymentState();
}

class _ReceivablePaymentState extends State<ReceivablePayment> {
  final _amountController = TextEditingController();
  String? _id;
  Receivable? _receivable;
  Customer? _customer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _id == null) {
      _id = args;
      final box = Hive.box<Receivable>('receivables');
      _receivable = box.get(_id);
      if (_receivable != null) {
        final customers = Hive.box<Customer>('customers');
        _customer = customers.get(_receivable!.customerId);
      }
    }
  }

  void _record() {
    if (_receivable == null) return;
    final pay = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (pay <= 0) return;
    final remaining = _receivable!.remaining;
    final actualPay = pay > remaining ? remaining : pay;

    _receivable!.paid += actualPay;
    _receivable!.remaining = _receivable!.amount - _receivable!.paid;

    if (_customer != null) {
      _customer!.paid += actualPay;
      _customer!.remaining = _customer!.totalPurchases - _customer!.paid;
      Hive.box<Customer>('customers').put(_customer!.id, _customer!);
    }

    final receivableBox = Hive.box<Receivable>('receivables');
    if (_receivable!.remaining <= 0) {
      receivableBox.delete(_receivable!.id);
    } else {
      receivableBox.put(_receivable!.id, _receivable!);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_receivable == null) {
      return PopScopeCompat(onPop: () => handleWillPop(context), child: Scaffold(appBar: AppBar(title: const Text('Payment')), body: const Center(child: Text('Receivable not found'))));
    }
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Record Payment')),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Customer: ${_customer?.name ?? _receivable!.customerId}'),
              Text('Remaining: ${_receivable!.remaining.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              TextField(controller: _amountController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Payment Amount')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _record, child: const Text('Record')),
            ],
          ),
        ),
      ),
    );
  }
}
