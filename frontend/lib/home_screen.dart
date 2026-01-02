import 'package:flutter/material.dart';

import 'utils.dart';
import 'personal_data_form.dart';
import 'login_screen.dart';
import 'leave_form.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DREAM BOT HR PORTAL'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.7),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/dream_bot_logo.png',
                      height: 100,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome to the Employee Portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildMenuButton(
                      context,
                      icon: Icons.person,
                      label: 'Personal Data Form',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PersonalDataForm()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildMenuButton(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Leave Application Form',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaveFormScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 60),
                    const Divider(),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.black54),
                      label: const Text(
                        'Admin Login',
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ).copyWith(
        backgroundColor: MaterialStateProperty.all(Colors.white.withOpacity(0.9)),
        foregroundColor: MaterialStateProperty.all(Colors.black),
        elevation: MaterialStateProperty.all(4),
      ),
    );
  }
}