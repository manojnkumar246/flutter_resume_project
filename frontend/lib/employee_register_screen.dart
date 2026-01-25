import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'utils.dart';
import 'employee_login_screen.dart';

class EmployeeRegisterScreen extends StatefulWidget {
  const EmployeeRegisterScreen({super.key});

  @override
  State<EmployeeRegisterScreen> createState() => _EmployeeRegisterScreenState();
}

class _EmployeeRegisterScreenState extends State<EmployeeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _resultMessage = '';
  bool _isSuccess = false;

  // Controllers
  final Map<String, TextEditingController> _ctrls = {};
  String _maritalStatus = '';
  Uint8List? _selectedImageBytes;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Focus Nodes
  final Map<String, FocusNode> _focusNodes = {};

  // Ordered keys for form fields
  final List<String> _orderedKeys = [
    'name', 'fatherName', 'dob', 'qualification',
    'maritalStatus',
    'passport', 'license', 'aadhar', 'pan',
    'localAddress', 'permanentAddress',
    'mobile', 'residenceTel', 'email',
    'password', 'confirmPassword', // New password fields
    'emergencyContact', 'bloodGroup',
    'bankName', 'branch', 'ifsc',
    'accountName', 'accountNumber',
  ];

  final List<String> maritalOptions = [
    'Single',
    'Married',
    'Unmarried',
    'Divorced',
    'Widowed'
  ];

  @override
  void initState() {
    super.initState();
    for (var k in _orderedKeys) {
      if (k != 'maritalStatus') _ctrls[k] = TextEditingController();
      _focusNodes[k] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) {
      c.dispose();
    }
    for (var f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _removeImage() => setState(() => _selectedImageBytes = null);

  Future<void> _selectDate(TextEditingController ctrl) async {
    DateTime? pick = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Colors.black, onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (pick != null) ctrl.text = DateFormat('dd/MM/yyyy').format(pick);
  }

  void _focusNext(String currentKey) {
    int index = _orderedKeys.indexOf(currentKey);
    if (index != -1 && index < _orderedKeys.length - 1) {
      _focusNodes[_orderedKeys[index + 1]]?.requestFocus();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fix errors'), backgroundColor: Colors.red),
      );
      return;
    }

    // Check password match
    if (_ctrls['password']!.text != _ctrls['confirmPassword']!.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{};
    for (var k in _ctrls.keys) {
      if (k != 'confirmPassword') {
        data[k] = _ctrls[k]!.text;
      }
    }
    data['maritalStatus'] = _maritalStatus;
    data['photoBase64'] =
        _selectedImageBytes != null ? base64Encode(_selectedImageBytes!) : '';

    try {
      final response = await http.post(
        Uri.parse('$kBackendBase/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        final empCode = result['empCode'] ?? 'N/A';
        
        setState(() {
          _resultMessage = 'Registration successful!\nYour Employee ID: $empCode\nPlease login.';
          _isSuccess = true;
        });

        // Show dialog with employee ID
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Registration Successful! ✅'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your account has been created.'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Column(
                      children: [
                        const Text('Your Employee ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(empCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Please save this ID. It cannot be changed.', 
                    style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const EmployeeLoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('Go to Login', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _resultMessage = error['error'] ?? 'Registration failed';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _field(
    String label,
    String key, {
    String? Function(String?)? validator,
    bool isDate = false,
    bool isPassword = false,
    TextInputFormatter? formatter,
  }) {
    int orderIndex = _orderedKeys.indexOf(key);

    bool obscure = false;
    if (key == 'password') obscure = _obscurePassword;
    if (key == 'confirmPassword') obscure = _obscureConfirmPassword;

    return FocusTraversalOrder(
      order: NumericFocusOrder(orderIndex.toDouble()),
      child: SizedBox(
        height: isPassword ? 52 : 42,
        child: TextFormField(
          controller: _ctrls[key],
          focusNode: _focusNodes[key],
          obscureText: isPassword ? obscure : false,
          readOnly: isDate,
          style: const TextStyle(fontSize: 13),
          onTap: isDate ? () => _selectDate(_ctrls[key]!) : null,
          inputFormatters: formatter != null ? [formatter] : [],
          validator: validator ?? Validators.required,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _focusNext(key),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: isDate
                ? const Icon(Icons.calendar_today,
                    size: 14, color: Colors.black)
                : isPassword
                    ? IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            if (key == 'password') {
                              _obscurePassword = !_obscurePassword;
                            } else {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            }
                          });
                        },
                      )
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _dropdown() {
    String key = 'maritalStatus';
    int orderIndex = _orderedKeys.indexOf(key);

    return FocusTraversalOrder(
      order: NumericFocusOrder(orderIndex.toDouble()),
      child: SizedBox(
        height: 42,
        child: DropdownButtonFormField<String>(
          initialValue:
              maritalOptions.contains(_maritalStatus) ? _maritalStatus : null,
          focusNode: _focusNodes[key],
          style: const TextStyle(fontSize: 13, color: Colors.black),
          decoration: const InputDecoration(labelText: 'Marital Status'),
          items: maritalOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            setState(() => _maritalStatus = v!);
            _focusNext(key);
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
      ),
    );
  }

  Widget _photoBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Photo",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            color: Colors.grey[100],
          ),
          child: _selectedImageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: _removeImage,
                        child: Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 20, color: Colors.black54),
                      SizedBox(height: 4),
                      Text("Add Photo",
                          style:
                              TextStyle(fontSize: 10, color: Colors.black87)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.black38)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const Expanded(child: Divider(color: Colors.black38)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Employee Registration'),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.85),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Form(
                  key: _formKey,
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Icon(Icons.person_add, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'New Employee Registration',
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

                        // Personal Info Section
                        _sectionHeader('Personal Information'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: _field('Full Name *', 'name',
                                            validator: Validators.alpha)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _field(
                                            "Father's Name", 'fatherName',
                                            validator: Validators.alpha)),
                                  ]),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    Expanded(
                                        child: _field('Date of Birth', 'dob',
                                            isDate: true)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _field(
                                            'Qualification', 'qualification')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _dropdown()),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            _photoBox(),
                          ],
                        ),

                        // ID Documents Section
                        _sectionHeader('ID Documents'),
                        Row(children: [
                          Expanded(
                              child: _field('Passport No.', 'passport',
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Driving License', 'license',
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Aadhar No.', 'aadhar',
                                  validator: Validators.numeric)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('PAN No.', 'pan',
                                  validator: Validators.alphaNumeric)),
                        ]),

                        // Address Section
                        _sectionHeader('Address'),
                        Row(children: [
                          Expanded(
                              child: _field('Local Address', 'localAddress')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field(
                                  'Permanent Address', 'permanentAddress')),
                        ]),

                        // Contact Section
                        _sectionHeader('Contact Information'),
                        Row(children: [
                          Expanded(
                              child: _field('Mobile *', 'mobile',
                                  validator: Validators.phone)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Residence Tel.', 'residenceTel',
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Email *', 'email',
                                  validator: Validators.email)),
                        ]),

                        // Password Section (NEW)
                        _sectionHeader('Account Credentials'),
                        Row(children: [
                          Expanded(
                            child: _field(
                              'Password *',
                              'password',
                              isPassword: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'Confirm Password *',
                              'confirmPassword',
                              isPassword: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v != _ctrls['password']!.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ),
                        ]),

                        // Emergency Contact
                        _sectionHeader('Emergency & Bank Details'),
                        Row(children: [
                          Expanded(
                              child: _field(
                                  'Emergency Contact', 'emergencyContact',
                                  validator: Validators.phone)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Blood Group', 'bloodGroup',
                                  validator: Validators.optional)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _field('Bank Name', 'bankName',
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Branch', 'branch',
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('IFSC Code', 'ifsc',
                                  validator: Validators.optional)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _field('Account Name', 'accountName',
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Account Number', 'accountNumber',
                                  validator: Validators.optional)),
                        ]),

                        const SizedBox(height: 32),

                        // Result Message
                        if (_resultMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: _isSuccess
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              border: Border.all(
                                  color:
                                      _isSuccess ? Colors.green : Colors.red),
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
                                            : Colors.red[800]),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Buttons
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
                              child: const Text('BACK TO LOGIN'),
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
                                  : const Text('REGISTER'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
