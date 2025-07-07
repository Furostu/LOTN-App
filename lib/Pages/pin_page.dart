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
  bool _isLoading = false;
  bool _isPinFocused = false;

  // Define the color palette from the first snippet
  static const Color black = Color(0xFF000000);
  static const Color darkGray1 = Color(0xFF1F1F1F);
  static const Color darkGray2 = Color(0xFF242424);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray1 = Color(0xFFF2F2F2);
  static const Color lightGray2 = Color(0xFFE2E2E2);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: lightGray1,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: lightGray2,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: black,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Admin Access',
                    style: TextStyle(
                      color: black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Lock icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [darkGray1, darkGray2],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Title
                      const Text(
                        'Enter Admin PIN',
                        style: TextStyle(
                          color: black,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      const Text(
                        'Please enter your PIN to access admin features',
                        style: TextStyle(
                          color: darkGray2,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 56),
                      // PIN Input Field
                      Container(
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _error != null
                                ? Colors.red
                                : _isPinFocused
                                ? black
                                : lightGray2,
                            width: _isPinFocused ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            setState(() {
                              _isPinFocused = hasFocus;
                            });
                          },
                          child: TextField(
                            controller: _pinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: black,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              hintText: '• • • •',
                              hintStyle: TextStyle(
                                color: darkGray2.withOpacity(0.7),
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 12,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                            ),
                            onChanged: (value) {
                              if (_error != null) {
                                setState(() {
                                  _error = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      // Error message
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 40),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            final enteredPin =
                            _pinController.text.trim();
                            final success = await auth.login(enteredPin);
                            if (success) {
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } else {
                              setState(() {
                                _error = 'Incorrect PIN. Please try again.';
                                _isLoading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: black,
                            foregroundColor: white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                white,
                              ),
                            ),
                          )
                              : const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Additional info
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: lightGray2,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Admin access allows you to add and manage songs',
                                style: TextStyle(
                                  color: darkGray2,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
