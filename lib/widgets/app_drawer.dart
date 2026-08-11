import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    Widget tile(String title, IconData icon, String routeName) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          selected: route == routeName,
          onTap: () {
            Navigator.pop(context);
            if (route != routeName) Navigator.pushReplacementNamed(context, routeName);
          },
        );

    final settings = Hive.box('settings');
    final business = (settings.get('businessName') as String?) ?? 'BizTrack';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
              child: Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.storefront, color: Colors.white)),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Local business ledger', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            tile('Dashboard', Icons.dashboard, '/dashboard'),
            tile('Add Products', Icons.inventory_2, '/products'),
            tile('Expenses', Icons.money_off, '/expenses'),
            tile('Customers', Icons.people, '/customers'),
            tile('Receivables', Icons.receipt_long, '/receivables'),
            tile('Reports', Icons.assessment, '/reports'),
            const Spacer(),
            const Divider(),
            tile('Settings', Icons.settings, '/settings'),
          ],
        ),
      ),
    );
  }
}
