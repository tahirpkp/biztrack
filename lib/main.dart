import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/product.dart';
import 'models/sale.dart';
import 'models/expense.dart';
import 'models/customer.dart';
import 'models/receivable.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard.dart';
import 'screens/sales_list.dart';
import 'screens/products_list.dart';
import 'screens/sale_form.dart';
import 'screens/expenses_list.dart';
import 'screens/expense_form.dart';
import 'screens/customers_list.dart';
import 'screens/customer_form.dart';
import 'screens/customer_detail.dart';
import 'screens/receivables_list.dart';
import 'screens/settings_screen.dart';
import 'screens/receivable_payment.dart';
import 'screens/reports_screen.dart';
import 'screens/sale_detail.dart';

import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(SaleAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(ReceivableAdapter());
  await Hive.openBox('settings');
  await Hive.openBox<Product>('products');
  await Hive.openBox<Sale>('sales');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<Receivable>('receivables');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final seed = Colors.indigo;
    final lightScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(
      primary: Colors.indigo.shade700,
      secondary: Colors.teal.shade600,
      surface: Colors.white,
      onSurface: Colors.black87,
    );
    final darkScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    return MaterialApp(
      title: 'BizTrack',
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        scaffoldBackgroundColor: lightScheme.surface,
        cardTheme: CardThemeData(color: lightScheme.surface, elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), backgroundColor: lightScheme.primary, foregroundColor: lightScheme.onPrimary)),
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: lightScheme.primary, foregroundColor: lightScheme.onPrimary, elevation: 2),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        scaffoldBackgroundColor: darkScheme.surface,
        cardTheme: CardThemeData(color: darkScheme.surfaceContainerHighest, elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), backgroundColor: darkScheme.primary, foregroundColor: darkScheme.onPrimary)),
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: darkScheme.primary, foregroundColor: darkScheme.onPrimary, elevation: 2),
      ),
      themeMode: themeProvider.mode,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const Dashboard(),
        '/sales': (context) => const SalesList(),
        '/products': (context) => const ProductsList(),
        '/add_sale': (context) => const SaleForm(),
        '/expenses': (context) => const ExpensesList(),
        '/add_expense': (context) => const ExpenseForm(),
        '/customers': (context) => const CustomersList(),
        '/add_customer': (context) => const CustomerForm(),
        '/customer_detail': (context) => const CustomerDetail(),
        '/receivables': (context) => const ReceivablesList(),
        '/receivable_payment': (context) => const ReceivablePayment(),
        '/sale_detail': (context) => const SaleDetail(),
        '/reports': (context) => const ReportsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
