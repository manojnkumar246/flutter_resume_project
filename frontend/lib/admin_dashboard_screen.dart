import 'package:flutter/material.dart';

import 'utils.dart';
import 'resume_list_screen.dart';
import 'leave_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Admin Dashboard'),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.7),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDashboardButton(
                  context,
                  icon: Icons.people,
                  label: 'Manage Personal Data',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumeListScreen())),
                ),
                const SizedBox(height: 20),
                _buildDashboardButton(
                  context,
                  icon: Icons.event_note,
                  label: 'Manage Leave Applications',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveListScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: 300,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 32),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
