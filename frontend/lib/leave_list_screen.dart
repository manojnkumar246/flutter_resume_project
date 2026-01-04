import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  List<dynamic> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$kBackendBase/leaves'));
      if (response.statusCode == 200) {
        setState(() {
          _leaves = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
            'Failed to load leaves: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Connection Error: $e', Colors.red);
    }
  }

  Future<void> _updateLeaveStatus(String id, String status) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Marking as $status...'),
          duration: const Duration(milliseconds: 800)),
    );

    try {
      final response = await http.put(
        Uri.parse('$kBackendBase/leaves/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Request Marked as $status!', Colors.green);
        _fetchLeaves(); // Refresh the list automatically
      } else {
        _showSnackBar('Server Error: ${response.body}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network Error: $e', Colors.red);
    }
  }

  Future<void> _deleteLeave(String id) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this leave request?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Deleting request...'),
          duration: Duration(milliseconds: 800)),
    );

    try {
      final response = await http.delete(
        Uri.parse('$kBackendBase/leaves/$id'),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Request Deleted!', Colors.green);
        _fetchLeaves(); // Refresh the list
      } else {
        _showSnackBar('Server Error: ${response.body}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        label = 'APPROVED';
        break;
      case 'denied':
        color = Colors.red;
        label = 'DENIED';
        break;
      default:
        color = Colors.orange;
        label = 'PENDING';
    }
    return Chip(
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Manage Leave Requests', actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchLeaves,
        ),
      ]),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.85),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _leaves.isEmpty
                  ? const Center(child: Text('No leave requests found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _leaves.length,
                      itemBuilder: (context, index) {
                        final leave = _leaves[index];
                        // Reverse the list to show newest first if backend doesn't sort
                        // or just use index as is.

                        final isPending = leave['status'] == 'pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(
                                color: Colors.black54, width: 0.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        leave['employeeName'] ?? 'No Name',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildStatusChip(
                                        leave['status'] ?? 'pending'),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteLeave(leave['id']),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Text('Type: ${leave['leaveType']}'),
                                const SizedBox(height: 4),
                                Text(
                                    'Dates: ${leave['startDate']} to ${leave['endDate']}'),
                                const SizedBox(height: 4),
                                Text('Reason: ${leave['reason'] ?? "None"}',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                if (isPending)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        label: const Text('Approve',
                                            style:
                                                TextStyle(color: Colors.green)),
                                        onPressed: () => _updateLeaveStatus(
                                            leave['id'], 'approved'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.cancel,
                                            color: Colors.red),
                                        label: const Text('Deny',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () => _updateLeaveStatus(
                                            leave['id'], 'denied'),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
