import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  static const Color deepBlue = Color(0xFF2E3192);
  static const Color offWhite = Color(0xFFF5F5F0);

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'Something went wrong. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No account found with that email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: offWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: deepBlue),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Reset your password',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: deepBlue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter the email associated with your account and we\'ll send a link to reset your password.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Send reset link',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 80, color: deepBlue),
        const SizedBox(height: 20),
        const Text(
          'Check your email',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: deepBlue,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a password reset link to ${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 30),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to login', style: TextStyle(color: deepBlue)),
        ),
      ],
    );
  }
}
