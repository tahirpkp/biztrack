import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/receivable.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _range;

  void _pickRange() async {
    final now = DateTime.now();
    final res = await showDateRangePicker(context: context, firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 1));
    if (!mounted) return;
    if (res != null) setState(() => _range = res);
  }

  Map<String, double> _compute() {
    final salesBox = Hive.box<Sale>('sales');
    final expensesBox = Hive.box<Expense>('expenses');
    final receivablesBox = Hive.box<Receivable>('receivables');
    final sList = salesBox.values.where((s) => _inRange(s.date)).toList();
    final eList = expensesBox.values.where((e) => _inRange(e.date)).toList();

    double sales = sList.fold(0.0, (p, e) => p + e.total);
    double expenses = eList.fold(0.0, (p, e) => p + e.amount);
    double profit = sales - expenses;
    double receivables = receivablesBox.values.fold(0.0, (p, r) => p + r.remaining);
    return {'sales': sales, 'expenses': expenses, 'profit': profit, 'receivables': receivables};
  }

  bool _inRange(DateTime dt) {
    if (_range == null) return true;
    return !dt.isBefore(_range!.start) && !dt.isAfter(_range!.end);
  }

  Future<void> _exportCsv() async {
    final salesBox = Hive.box<Sale>('sales');
    final sList = salesBox.values.where((s) => _inRange(s.date)).toList();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reports_${DateTime.now().toIso8601String()}.csv');
    final sink = file.openWrite();
    sink.writeln('type,id,customer,amount,date');
    for (var s in sList) {
      sink.writeln('sale,${s.id},"${s.customerName}",${s.total},${s.date.toIso8601String()}');
    }
    final expensesBox = Hive.box<Expense>('expenses');
    for (var e in expensesBox.values.where((e) => _inRange(e.date))) {
      sink.writeln('expense,${e.id},"${e.title}",${e.amount},${e.date.toIso8601String()}');
    }
    await sink.flush();
    await sink.close();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    final stats = _compute();
    final salesBox = Hive.box<Sale>('sales');
    final expensesBox = Hive.box<Expense>('expenses');
    final rows = <Map<String, dynamic>>[];
    for (var s in salesBox.values.where((s) => _inRange(s.date))) {
      rows.add({'type': 'Sale', 'id': s.id, 'label': s.customerName, 'amount': s.total, 'date': s.date});
    }
    for (var e in expensesBox.values.where((e) => _inRange(e.date))) {
      rows.add({'type': 'Expense', 'id': e.id, 'label': e.title, 'amount': e.amount, 'date': e.date});
    }

    rows.sort((a, b) => b['date'].compareTo(a['date']));

    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton(onPressed: _pickRange, child: const Text('Pick Date Range')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _range == null ? 'All time' : '${_range!.start.toLocal()} - ${_range!.end.toLocal()}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download), label: const Text('Export CSV')),
                ],
              ),
              const SizedBox(height: 12),
              Text('Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Metric')),
                      DataColumn(label: Text('Amount'), numeric: true),
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('Sales')),
                        DataCell(Text('Rs. ${stats['sales']!.toStringAsFixed(2)}')),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('Expenses')),
                        DataCell(Text('Rs. ${stats['expenses']!.toStringAsFixed(2)}')),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('Profit')),
                        DataCell(Text('Rs. ${stats['profit']!.toStringAsFixed(2)}')),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('Receivables')),
                        DataCell(Text('Rs. ${stats['receivables']!.toStringAsFixed(2)}')),
                      ]),
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
