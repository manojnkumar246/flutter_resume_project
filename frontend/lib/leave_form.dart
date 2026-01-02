import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'utils.dart';

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _resultMessage = '';

  // Controllers
  final _employeeNameCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String? _leaveType;

  final List<String> _leaveTypes = ['Casual Leave', 'Sick Leave', 'Earned Leave'];

  @override
  void dispose() {
    _employeeNameCtrl.dispose();
    _employeeIdCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form.'), backgroundColor: Colors.red),
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
      'leaveType': _leaveType,
      'startDate': _startDateCtrl.text,
      'endDate': _endDateCtrl.text,
      'reason': _reasonCtrl.text,
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
        });
        _formKey.currentState?.reset();
        _employeeNameCtrl.clear();
        _employeeIdCtrl.clear();
        _startDateCtrl.clear();
        _endDateCtrl.clear();
        _reasonCtrl.clear();
        setState(() {
          _leaveType = null;
        });
      } else {
        setState(() {
          _resultMessage = 'Error: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error submitting form: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Leave Application Form'),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.8),
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
                      Text('Submit a Leave Request', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _employeeNameCtrl,
                        decoration: const InputDecoration(labelText: 'Employee Name'),
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _employeeIdCtrl,
                        decoration: const InputDecoration(labelText: 'Employee ID'),
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _leaveType,
                        decoration: const InputDecoration(labelText: 'Leave Type'),
                        items: _leaveTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _leaveType = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a leave type' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _startDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _startDateCtrl),
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _endDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _endDateCtrl),
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Leave',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 32),
                      if (_isSubmitting)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('SUBMIT REQUEST'),
                        ),
                      if (_resultMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _resultMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _resultMessage.startsWith('Error') ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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