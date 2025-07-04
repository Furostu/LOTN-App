import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Admin PIN")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: 'PIN',
                errorText: _error,
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("Unlock"),
              onPressed: () async {
                final ok = await auth.tryPin(_pinController.text);
                if (!ok) {
                  setState(() => _error = "Wrong PIN");
                } else {
                  Navigator.pop(context);
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
