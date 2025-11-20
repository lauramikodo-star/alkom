import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step 1 Controllers
  final _ndCtrl = TextEditingController();
  final _ncliCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  // Step 2 Controller
  final _otpCtrl = TextEditingController();

  int _step = 1;

  void _submitStep1() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "nd": _ndCtrl.text.trim(),
      "ncli": _ncliCtrl.text.trim(),
      "mobile": _mobileCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "password": _passCtrl.text,
      "password_confirmation": _passConfirmCtrl.text,
      "lang": "fr"
    };

    final state = context.read<AppState>();
    final res = await state.register(data);

    if (!mounted) return;

    // Check response code. Python says code "5" means success requiring OTP.
    if (res['code'] == '5' || res['code'] == 5) {
       setState(() => _step = 2);
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('OTP sent to your mobile.')),
       );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(res['message'] ?? 'Registration failed')),
       );
    }
  }

  void _submitStep2() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) return;

    final state = context.read<AppState>();
    final res = await state.confirmRegister(_ndCtrl.text.trim(), otp);

    if (!mounted) return;

    // Check for token or success message
    if (res.toString().contains('token') || res['code'] == '0' || res['code'] == 0) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Registration Successful! Please Login.')),
       );
       Navigator.pop(context); // Go back to login
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(res['message'] ?? 'Confirmation failed')),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: _step == 1 ? _buildStep1(state) : _buildStep2(state),
        ),
      ),
    );
  }

  Widget _buildStep1(AppState state) {
    return Column(
      children: [
        TextFormField(
          controller: _ndCtrl,
          decoration: const InputDecoration(labelText: 'Fixed Number (ND)'),
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        TextFormField(
          controller: _ncliCtrl,
          decoration: const InputDecoration(labelText: 'Customer ID (NCLI)'),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        TextFormField(
          controller: _mobileCtrl,
          decoration: const InputDecoration(labelText: 'Mobile Number'),
          keyboardType: TextInputType.phone,
          validator: (v) => v!.length != 10 ? 'Must be 10 digits' : null,
        ),
        TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
        ),
        TextFormField(
          controller: _passCtrl,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          validator: (v) => v!.length < 8 ? 'Min 8 chars' : null,
        ),
        TextFormField(
          controller: _passConfirmCtrl,
          decoration: const InputDecoration(labelText: 'Confirm Password'),
          obscureText: true,
          validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
        ),
        const SizedBox(height: 24),
        if (state.loading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _submitStep1,
            child: const Text('Register'),
          ),
      ],
    );
  }

  Widget _buildStep2(AppState state) {
    return Column(
      children: [
        const Text('Enter the OTP sent to your mobile'),
        const SizedBox(height: 16),
        TextField(
          controller: _otpCtrl,
          decoration: const InputDecoration(labelText: 'OTP Code'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        if (state.loading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _submitStep2,
            child: const Text('Confirm & Finish'),
          ),
      ],
    );
  }
}
