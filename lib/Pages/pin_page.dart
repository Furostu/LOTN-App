import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/auth_service.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Admin PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please enter your admin PIN:'),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PIN',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final enteredPin = _pinController.text.trim();
                final success = await auth.login(enteredPin);

                if (success) {
                  if (context.mounted) Navigator.pop(context); // go back to SongListPage
                } else {
                  setState(() {
                    _error = 'Incorrect PIN';
                  });
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
