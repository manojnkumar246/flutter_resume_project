import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'utils.dart';
import 'services/auth_service.dart';

class EmployeeLeaveForm extends StatefulWidget {
  const EmployeeLeaveForm({super.key});

  @override
  State<EmployeeLeaveForm> createState() => _EmployeeLeaveFormState();
}

class _EmployeeLeaveFormState extends State<EmployeeLeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isSubmitting = false;
  String _resultMessage = '';
  bool _isSuccess = false;

  // Controllers - Employee data will be pre-filled
  late TextEditingController _employeeNameCtrl;
  late TextEditingController _employeeIdCtrl;
  late TextEditingController _employeeEmailCtrl;
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String? _leaveType;

  final List<String> _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Unpaid Leave',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill employee data from AuthService
    _employeeNameCtrl = TextEditingController(text: _authService.employeeName);
    _employeeIdCtrl = TextEditingController(text: _authService.employeeCode);
    _employeeEmailCtrl =
        TextEditingController(text: _authService.employeeEmail);
  }

  @override
  void dispose() {
    _employeeNameCtrl.dispose();
    _employeeIdCtrl.dispose();
    _employeeEmailCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _resultMessage = '';
    });

    final data = {
      'employeeName': _employeeNameCtrl.text,
      'employeeId': _employeeIdCtrl.text,
      'employeeEmail': _employeeEmailCtrl.text,
      'resumeId': _authService.employeeId, // Link to employee profile
      'leaveType': _leaveType,
      'startDate': _startDateCtrl.text,
      'endDate': _endDateCtrl.text,
      'reason': _reasonCtrl.text,
      'status': 'pending',
    };

    try {
      final response = await http.post(
        Uri.parse('$kBackendBase/leaves'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        setState(() {
          _resultMessage = 'Leave request submitted successfully!';
          _isSuccess = true;
        });
        // Clear only the leave-specific fields, keep employee data
        _startDateCtrl.clear();
        _endDateCtrl.clear();
        _reasonCtrl.clear();
        setState(() => _leaveType = null);
      } else {
        setState(() {
          _resultMessage = 'Error: ${response.statusCode}\n${response.body}';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error submitting form: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller,
      {DateTime? minDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minDate ?? DateTime.now(),
      firstDate: minDate ?? DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Colors.black, onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  int _calculateLeaveDays() {
    if (_startDateCtrl.text.isEmpty || _endDateCtrl.text.isEmpty) return 0;
    try {
      final start = DateFormat('yyyy-MM-dd').parse(_startDateCtrl.text);
      final end = DateFormat('yyyy-MM-dd').parse(_endDateCtrl.text);
      return end.difference(start).inDays + 1;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveDays = _calculateLeaveDays();

    return Scaffold(
      appBar: buildAppBar('Leave Application'),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.85),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(Icons.event_note, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Leave Application Form',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: Colors.black),

                      // Employee Info Section (Read-only, pre-filled)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  'Employee Information (Auto-filled from your profile)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _employeeNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Employee Name',
                                      fillColor: Colors.white,
                                    ),
                                    readOnly: true,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _employeeIdCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Employee ID',
                                      fillColor: Colors.white,
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _employeeEmailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                fillColor: Colors.white,
                              ),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Leave Details Section
                      const Text(
                        'Leave Details',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),

                      // Leave Type
                      DropdownButtonFormField<String>(
                        initialValue: _leaveType,
                        decoration:
                            const InputDecoration(labelText: 'Leave Type *'),
                        items: _leaveTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() => _leaveType = newValue);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a leave type' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date Selection
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Start Date *',
                                suffixIcon:
                                    Icon(Icons.calendar_today, size: 18),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context, _startDateCtrl),
                              validator: Validators.required,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endDateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'End Date *',
                                suffixIcon:
                                    Icon(Icons.calendar_today, size: 18),
                              ),
                              readOnly: true,
                              onTap: () {
                                DateTime? minDate;
                                if (_startDateCtrl.text.isNotEmpty) {
                                  minDate = DateFormat('yyyy-MM-dd')
                                      .parse(_startDateCtrl.text);
                                }
                                _selectDate(context, _endDateCtrl,
                                    minDate: minDate);
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (_startDateCtrl.text.isNotEmpty) {
                                  final start = DateFormat('yyyy-MM-dd')
                                      .parse(_startDateCtrl.text);
                                  final end = DateFormat('yyyy-MM-dd').parse(v);
                                  if (end.isBefore(start))
                                    return 'End date must be after start';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      // Leave Duration Display
                      if (leaveDays > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Leave Days: $leaveDays',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Reason
                      TextFormField(
                        controller: _reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Leave *',
                          alignLabelWithHint: true,
                          hintText:
                              'Please provide details for your leave request...',
                        ),
                        maxLines: 4,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 24),

                      // Result Message
                      if (_resultMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color:
                                _isSuccess ? Colors.green[50] : Colors.red[50],
                            border: Border.all(
                                color: _isSuccess ? Colors.green : Colors.red),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSuccess ? Icons.check_circle : Icons.error,
                                color: _isSuccess ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _resultMessage,
                                  style: TextStyle(
                                    color: _isSuccess
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Submit Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                            child: const Text('CANCEL'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('SUBMIT REQUEST'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
