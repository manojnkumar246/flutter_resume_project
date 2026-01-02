import 'package:flutter/material.dart';

import 'utils.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  String _err = '';

  void _login() {
    if (_u.text == 'admin' && _p.text == 'password') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } else {
      setState(() => _err = 'Invalid credentials');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Admin Login'),
      body: Stack(
        children: [
          buildBackground(),
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: Colors.white, border: Border.all(color: Colors.black)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 50),
                  const SizedBox(height: 20),
                  const Text('ADMIN PORTAL',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 30),
                  TextField(
                      controller: _u,
                      decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 15),
                  TextField(
                      controller: _p,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password')),
                  if (_err.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_err,
                            style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 30),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _login, child: const Text('LOGIN'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
