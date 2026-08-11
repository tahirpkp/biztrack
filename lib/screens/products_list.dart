import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class ProductsList extends StatefulWidget {
  const ProductsList({super.key});

  @override
  State<ProductsList> createState() => _ProductsListState();
}

class _ProductsListState extends State<ProductsList> {
  Box<Product> get productsBox => Hive.box<Product>('products');
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '0');
  final _uuid = const Uuid();
  String? _editingId;

  void _openEditor([Product? p]) {
    if (p != null) {
      _editingId = p.id;
      _nameController.text = p.name;
      _priceController.text = p.price.toString();
      _qtyController.text = p.quantity.toString();
    } else {
      _editingId = null;
      _nameController.clear();
      _priceController.clear();
      _qtyController.text = '0';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 8),
              TextField(controller: _priceController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price')),
              const SizedBox(height: 8),
              TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                      final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
                      if (name.isEmpty || price <= 0) return;
                      final id = _editingId ?? _uuid.v4();
                      final prod = Product(id: id, name: name, quantity: qty, price: price);
                      productsBox.put(id, prod);
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = productsBox.values.toList().reversed.toList();
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Products')),
        drawer: const AppDrawer(),
        body: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(p.name),
                subtitle: Text('Price: ${p.price.toStringAsFixed(2)} • Qty: ${p.quantity}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditor(p)),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Confirm'), content: const Text('Delete this product?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes'))]));
                        if (confirm == true) {
                          await productsBox.delete(p.id);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(onPressed: () => _openEditor(), child: const Icon(Icons.add)),
      ),
    );
  }
}
