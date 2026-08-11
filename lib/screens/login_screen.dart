import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSetting = false;
  String? _storedPin;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _storedPin = box.get('pin');
    _isSetting = _storedPin == null;
  }

  void _savePin() {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be at least 4 digits')));
      return;
    }
    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }
    Hive.box('settings').put('pin', pin);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
  }

  void _login() {
    final pin = _pinController.text.trim();
    if (pin == _storedPin) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'PIN'),
            ),
            if (_isSetting) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSetting ? _savePin : _login,
              child: Text(_isSetting ? 'Set PIN' : 'Login'),
            ),
            if (!_isSetting) ...[
              TextButton(
                onPressed: () {
                  // allow resetting PIN (clears stored pin)
                  Hive.box('settings').delete('pin');
                  setState(() {
                    _isSetting = true;
                    _storedPin = null;
                    _pinController.clear();
                    _confirmController.clear();
                  });
                },
                child: const Text('Reset PIN'),
              )
            ]
          ],
        ),
      ),
    );
  }
}
