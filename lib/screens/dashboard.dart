import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/receivable.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class _SaleOrderLine {
  final String id;
  String name;
  int quantity;
  double price;

  _SaleOrderLine({
    required this.id,
    required this.name,
    this.quantity = 1,
    required this.price,
  });

  double get total => price * quantity;
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Box<Sale> get salesBox => Hive.box<Sale>('sales');
  Box<Expense> get expensesBox => Hive.box<Expense>('expenses');
  Box<Receivable> get receivableBox => Hive.box<Receivable>('receivables');
  Box<Customer> get customersBox => Hive.box<Customer>('customers');
  Box<Product> get productsBox => Hive.box<Product>('products');

  double _todaySales = 0.0;
  double _todayExpenses = 0.0;
  double _receivables = 0.0;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() {
    final today = DateTime.now();
    double sales = 0.0;
    for (var s in salesBox.values) {
      if (_isSameDay(s.date, today)) sales += s.total;
    }
    double expenses = 0.0;
    for (var e in expensesBox.values) {
      if (_isSameDay(e.date, today)) expenses += e.amount;
    }
    double recv = 0.0;
    for (var r in receivableBox.values) {
      recv += r.remaining;
    }
    setState(() {
      _todaySales = sales;
      _todayExpenses = expenses;
      _receivables = recv;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showNewSaleSheet() {
    final orderItems = <_SaleOrderLine>[];
    final customerController = TextEditingController();
    final phoneController = TextEditingController();
    final paymentController = TextEditingController();
    final customNameController = TextEditingController();
    final customPriceController = TextEditingController();
    final customQuantityController = TextEditingController(text: '1');
    final ledgerController = TextEditingController();
    final uuid = const Uuid();

    void addOrderItem(_SaleOrderLine item, StateSetter setSheetState) {
      final existing = orderItems.indexWhere((e) => e.name == item.name && e.price == item.price);
      if (existing >= 0) {
        setSheetState(() {
          orderItems[existing].quantity += item.quantity;
        });
      } else {
        setSheetState(() {
          orderItems.add(item);
        });
      }
    }

    void saveSale(StateSetter setSheetState) {
      final customerName = customerController.text.trim();
      if (customerName.isEmpty || orderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer name and at least one item are required')));
        return;
      }
      final payment = double.tryParse(paymentController.text.trim()) ?? 0.0;
      final total = orderItems.fold(0.0, (sum, item) => sum + item.total);
      final customerPhone = phoneController.text.trim();
      final ledgerNumber = ledgerController.text.trim();
      final customers = Hive.box<Customer>('customers');
      final sales = Hive.box<Sale>('sales');
      final receivables = Hive.box<Receivable>('receivables');

      Customer? existingCustomer;
      if (customerPhone.isNotEmpty) {
        existingCustomer = customers.values.cast<Customer?>().firstWhere(
          (c) => c != null && c.phone == customerPhone,
          orElse: () => null,
        );
      }
      if (existingCustomer == null && ledgerNumber.isNotEmpty) {
        existingCustomer = customers.values.cast<Customer?>().firstWhere(
          (c) => c != null && c.ledgerNumber == ledgerNumber,
          orElse: () => null,
        );
      }

      final customerId = existingCustomer?.id ?? uuid.v4();
      final customer = existingCustomer != null
          ? Customer(
              id: customerId,
              name: customerName,
              phone: customerPhone.isNotEmpty ? customerPhone : existingCustomer.phone,
              ledgerNumber: ledgerNumber.isNotEmpty ? ledgerNumber : existingCustomer.ledgerNumber,
              totalPurchases: existingCustomer.totalPurchases + total,
              paid: existingCustomer.paid + payment,
              remaining: existingCustomer.remaining + (total - payment),
              createdAt: existingCustomer.createdAt,
            )
          : Customer(
              id: customerId,
              name: customerName,
              phone: customerPhone,
              ledgerNumber: ledgerNumber,
              totalPurchases: total,
              paid: payment,
              remaining: total - payment,
              createdAt: DateTime.now(),
            );

      final saleId = uuid.v4();
      sales.put(
        saleId,
        Sale(
          id: saleId,
          customerId: customerId,
          customerName: customerName,
          products: orderItems
              .map((item) => Product(id: uuid.v4(), name: item.name, quantity: item.quantity, price: item.price, discount: 0.0))
              .toList(),
          total: total,
          payment: payment,
          date: DateTime.now(),
        ),
      );
      customers.put(customerId, customer);
      if (payment < total) {
        receivables.put(
          saleId,
          Receivable(
            id: saleId,
            customerId: customerId,
            amount: total,
            paid: payment,
            remaining: total - payment,
            createdAt: DateTime.now(),
          ),
        );
      }
      Navigator.of(context).pop();
      setState(_recompute);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (contextSheet) {
        final products = Hive.box<Product>('products').values.toList();
        final customers = Hive.box<Customer>('customers');
        Customer? findCustomer() {
          final customerPhone = phoneController.text.trim();
          final ledgerNumber = ledgerController.text.trim();
          Customer? found;
          if (customerPhone.isNotEmpty) {
            found = customers.values.cast<Customer?>().firstWhere(
              (c) => c != null && c.phone == customerPhone,
              orElse: () => null,
            );
          }
          if (found == null && ledgerNumber.isNotEmpty) {
            found = customers.values.cast<Customer?>().firstWhere(
              (c) => c != null && c.ledgerNumber == ledgerNumber,
              orElse: () => null,
            );
          }
          return found;
        }
        void tryLoadCustomer(StateSetter setSheetState) {
          final matched = findCustomer();
          if (matched != null) {
            setSheetState(() {
              if (customerController.text.trim().isEmpty) {
                customerController.text = matched.name;
              }
              if (phoneController.text.trim().isEmpty) {
                phoneController.text = matched.phone;
              }
              if (ledgerController.text.trim().isEmpty) {
                ledgerController.text = matched.ledgerNumber;
              }
            });
          }
        }
        return StatefulBuilder(builder: (contextSheet, setSheetState) {
          final total = orderItems.fold(0.0, (sum, item) => sum + item.total);
          final payment = double.tryParse(paymentController.text.trim()) ?? 0.0;
          final remaining = total - payment;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(contextSheet).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(height: 4, width: 48, color: Colors.grey.shade400)),
                    const SizedBox(height: 16),
                    Text('New Sale', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    TextField(controller: customerController, decoration: const InputDecoration(labelText: 'Customer Name')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Customer Phone (optional)'),
                      onChanged: (_) => tryLoadCustomer(setSheetState),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ledgerController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(labelText: 'Ledger Number (optional)'),
                      onChanged: (_) => tryLoadCustomer(setSheetState),
                    ),
                    const SizedBox(height: 20),
                    Text('Products', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        children: products.map((product) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product.name),
                              subtitle: Text(product.price.toStringAsFixed(2)),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => addOrderItem(
                                  _SaleOrderLine(id: uuid.v4(), name: product.name, price: product.price),
                                  setSheetState,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Custom Order Item', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: customNameController, decoration: const InputDecoration(labelText: 'Name'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: customPriceController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: customQuantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final name = customNameController.text.trim();
                            final price = double.tryParse(customPriceController.text.trim()) ?? 0.0;
                            final qty = int.tryParse(customQuantityController.text.trim()) ?? 1;
                            if (name.isEmpty || price <= 0 || qty <= 0) return;
                            addOrderItem(_SaleOrderLine(id: uuid.v4(), name: name, price: price, quantity: qty), setSheetState);
                            customNameController.clear();
                            customPriceController.clear();
                            customQuantityController.text = '1';
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Order Summary', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...orderItems.map((item) => ListTile(
                          title: Text('${item.name} ×${item.quantity}'),
                          subtitle: Text(item.price.toStringAsFixed(2)),
                          trailing: Text(item.total.toStringAsFixed(2)),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        )),
                    if (orderItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No items added yet', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    const SizedBox(height: 12),
                    Text('Total: Rs. ${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                    TextField(controller: paymentController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Payment amount')),
                    const SizedBox(height: 12),
                    Text('Remaining: Rs. ${remaining.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: () => saveSale(setSheetState), child: const Text('Save Sale')),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final net = _todaySales - _todayExpenses;
    final recentSales = salesBox.values.toList().reversed.take(5).toList();
    final recentExpenses = expensesBox.values.toList().reversed.take(5).toList();
    final recentCustomers = customersBox.values.toList().reversed.take(5).toList();

    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: () async => _recompute(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(width: cardWidth, child: _summaryCard('Today\'s Sales', _todaySales, Icons.point_of_sale, Theme.of(context).colorScheme.primary)) ,
                        SizedBox(width: cardWidth, child: _summaryCard('Today\'s Expenses', _todayExpenses, Icons.money_off, Theme.of(context).colorScheme.error)) ,
                        SizedBox(width: cardWidth, child: _summaryCard('Net Profit', net, Icons.show_chart, Theme.of(context).colorScheme.secondaryContainer)) ,
                        SizedBox(width: cardWidth, child: _summaryCard('Receivables', _receivables, Icons.receipt_long, Theme.of(context).colorScheme.tertiaryContainer)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _showNewSaleSheet,
                      icon: const Icon(Icons.add_shopping_cart, size: 22),
                      label: const Text('New Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final sectionWidth = width >= 1080
                        ? (width - 24) / 3
                        : width >= 720
                            ? (width - 12) / 2
                            : width;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: sectionWidth,
                          child: _sectionCard(
                            context,
                            title: 'Recent Sales',
                            color: Colors.blue.shade100,
                            items: [
                              _tableHeaderRow(context, ['Customer', 'Items', 'Total'], flexes: [3, 1, 1]),
                              ...recentSales.map((s) {
                                final itemCount = s.products.fold<int>(0, (count, product) => count + product.quantity);
                                return _tableRow(
                                  context,
                                  leading: s.customerName,
                                  middle: '$itemCount item${itemCount == 1 ? '' : 's'}',
                                  trailing: 'Rs. ${s.total.toStringAsFixed(2)}',
                                  onTap: () => Navigator.pushNamed(context, '/sale_detail', arguments: s.id),
                                );
                              }),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: _sectionCard(
                            context,
                            title: 'Recent Expenses',
                            color: Theme.of(context).colorScheme.errorContainer,
                            items: [
                              _tableHeaderRow(context, ['Title', 'Category', 'Amount'], flexes: [3, 2, 1]),
                              ...recentExpenses.map((e) => _tableRow(
                                    context,
                                    leading: e.title,
                                    middle: e.category,
                                    trailing: 'Rs. ${e.amount.toStringAsFixed(2)}',
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: _sectionCard(
                            context,
                            title: 'Recent Customers',
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            items: [
                              _tableHeaderRow(context, ['Name', 'Phone', 'Remaining'], flexes: [3, 2, 1]),
                              ...recentCustomers.map((c) => _tableRow(
                                    context,
                                    leading: c.name,
                                    middle: c.phone.isEmpty ? '—' : c.phone,
                                    trailing: 'Rs. ${c.remaining.toStringAsFixed(2)}',
                                    onTap: () => Navigator.pushNamed(context, '/customer_detail', arguments: c.id),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double amount, IconData icon, Color color) {
    final isLight = Theme.of(context).colorScheme.brightness == Brightness.light;
    return Card(
      elevation: 1,
      color: isLight ? Colors.white : Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: color.withAlpha((0.15 * 255).round()), borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 18),
            Text('Rs. ${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required Color color, required List<Widget> items}) {
    final isLight = Theme.of(context).colorScheme.brightness == Brightness.light;
    final displayedItems = items.take(6).toList();
    final hasDataRows = displayedItems.length > 1;
    return Card(
      color: isLight ? Colors.white : Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (!hasDataRows)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No records yet', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            for (var i = 0; i < displayedItems.length; i++) ...[
              displayedItems[i],
              if (i != displayedItems.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
        ],
      ),
    );
  }

  Widget _tableHeaderRow(BuildContext context, List<String> columns, {List<int>? flexes}) {
    final effectiveFlexes = flexes ?? [2, 2, 1];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(columns.length, (index) {
          return Expanded(
            flex: effectiveFlexes[index],
            child: Text(
              columns[index],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: index == columns.length - 1 ? TextAlign.right : TextAlign.left,
            ),
          );
        }),
      ),
    );
  }

  Widget _tableRow(BuildContext context, {required String leading, required String middle, required String trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(leading, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(middle, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Text(trailing, textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

}
