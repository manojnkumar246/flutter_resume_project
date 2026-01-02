import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'utils.dart';
import 'login_screen.dart';

class PersonalDataForm extends StatefulWidget {
  final String? resumeId;
  final bool isViewOnly;
  final http.Client? client;

  const PersonalDataForm(
      {super.key, this.resumeId, this.isViewOnly = false, this.client});

  @override
  State<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends State<PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _resultMessage = '';

  // Controllers
  final Map<String, TextEditingController> _ctrls = {};
  String _maritalStatus = '';
  Uint8List? _selectedImageBytes;

  // --- FOCUS NODES MAP ---
  final Map<String, FocusNode> _focusNodes = {};

  // --- ORDERED KEYS FOR TAB NAVIGATION ---
  final List<String> _orderedKeys = [
    'name', 'fatherName', 'dob', 'qualification',
    'maritalStatus', // Row 1 & 2 & 3
    'passport', 'license', 'aadhar', 'pan', // IDs
    'localAddress', 'permanentAddress', // Address
    'mobile', 'residenceTel', 'email', // Contact
    'emergencyContact', 'bloodGroup',
    'bankName', 'branch', 'ifsc', // Bank
    'accountName', 'accountNumber',
    'empCode', 'doj', 'designation' // HR
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
    // Initialize Controllers and FocusNodes
    for (var k in _orderedKeys) {
      if (k != 'maritalStatus') _ctrls[k] = TextEditingController();
      _focusNodes[k] = FocusNode();
    }
    if (widget.resumeId != null) _fetchResume();
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) c.dispose();
    for (var f in _focusNodes.values) f.dispose();
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

  Future<void> _fetchResume() async {
    try {
      final res =
          await http.get(Uri.parse('$kBackendBase/resumes/${widget.resumeId}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          for (var k in _ctrls.keys) _ctrls[k]!.text = data[k] ?? '';
          _maritalStatus = data['maritalStatus'] ?? '';
          if (data['photoBase64'] != null && data['photoBase64'].isNotEmpty) {
            try {
              _selectedImageBytes = base64Decode(data['photoBase64']);
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fix errors'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);

    final data = {for (var k in _ctrls.keys) k: _ctrls[k]!.text};
    data['maritalStatus'] = _maritalStatus;
    data['photoBase64'] =
        _selectedImageBytes != null ? base64Encode(_selectedImageBytes!) : '';

    try {
      final url = widget.resumeId == null
          ? Uri.parse('$kBackendBase/resume')
          : Uri.parse('$kBackendBase/resumes/${widget.resumeId}');

      final client = widget.client ?? http.Client();
      final res = widget.resumeId == null
          ? await client.post(url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(data))
          : await client.put(url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(data));

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _resultMessage = "Saved Successfully!");
        if (widget.resumeId == null) {
          _formKey.currentState!.reset();
          for (var c in _ctrls.values) c.clear();
          _maritalStatus = '';
          _selectedImageBytes = null;
          // Refocus on top
          _focusNodes['name']?.requestFocus();
        }
      } else {
        setState(() => _resultMessage = "Failed: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => _resultMessage = "Error: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    DateTime? pick = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1950),
        lastDate: DateTime(2030),
        builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: Colors.black, onSurface: Colors.black)),
            child: child!));
    if (pick != null) ctrl.text = DateFormat('dd/MM/yyyy').format(pick);
  }

  void _focusNext(String currentKey) {
    int index = _orderedKeys.indexOf(currentKey);
    if (index != -1 && index < _orderedKeys.length - 1) {
      _focusNodes[_orderedKeys[index + 1]]?.requestFocus();
    }
  }

  Widget _field(String label, String key,
      {String? Function(String?)? validator,
      bool isDate = false,
      bool locked = false, // If true, field is Read-Only (for Employee)
      TextInputFormatter? formatter}) {
    int orderIndex = _orderedKeys.indexOf(key);

    return FocusTraversalOrder(
      order: NumericFocusOrder(orderIndex.toDouble()),
      child: SizedBox(
        height: 42,
        child: TextFormField(
          controller: _ctrls[key],
          focusNode: _focusNodes[key],
          // Can focus only if not view-only AND not locked
          canRequestFocus: !widget.isViewOnly && !locked,
          // Read-Only if view-only OR isDate OR locked
          readOnly: widget.isViewOnly || isDate || locked,
          style: const TextStyle(fontSize: 13),
          // Date Picker opens only if NOT view-only AND NOT locked
          onTap: isDate && !widget.isViewOnly && !locked
              ? () => _selectDate(_ctrls[key]!)
              : null,
          inputFormatters: formatter != null ? [formatter] : [],
          validator: validator ?? Validators.required,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _focusNext(key),
          decoration: InputDecoration(
            labelText: label,
            // If locked, maybe grey out background slightly?
            fillColor: locked ? Colors.grey[200] : Colors.white,
            suffixIcon: isDate
                ? const Icon(Icons.calendar_today,
                    size: 14, color: Colors.black)
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
          value:
              maritalOptions.contains(_maritalStatus) ? _maritalStatus : null,
          focusNode: _focusNodes[key],
          style: const TextStyle(fontSize: 13, color: Colors.black),
          decoration: const InputDecoration(labelText: 'Marital Status'),
          items: maritalOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: widget.isViewOnly
              ? null
              : (v) {
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
              color: Colors.grey[100]),
          child: _selectedImageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                    if (!widget.isViewOnly)
                      Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                              onTap: _removeImage,
                              child: Container(
                                  color: Colors.white.withOpacity(0.7),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.red)))),
                  ],
                )
              : widget.isViewOnly
                  ? const Center(
                      child: Text("No Photo", style: TextStyle(fontSize: 10)))
                  : InkWell(
                      onTap: _pickImage,
                      child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 20, color: Colors.black54),
                            SizedBox(height: 4),
                            Text("Add File",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.black87))
                          ]),
                    ),
        ),
      ],
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration: TextDecoration.underline)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double rowGap = 10;
    // Determine if we are in "Employee" mode (New Entry)
    // If resumeId is NULL, it is an Employee filling the form -> Lock HR fields.
    bool isEmployee = widget.resumeId == null;

    return Scaffold(
      appBar: buildAppBar(
          widget.isViewOnly ? 'View Resume' : 'Personal Data Form',
          actions: [
            if (!widget.isViewOnly && widget.resumeId == null)
              IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())))
          ]),
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            buildBackground(),
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                height: 80,
                                width: 200,
                                alignment: Alignment.center,
                                child: Image.asset(
                                    'assets/images/dream_bot_logo.png',
                                    errorBuilder: (_, __, ___) => const Text(
                                        "DREAM BOT",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20))),
                              ),
                            ),
                            const Divider(
                                color: Colors.black, height: 15, thickness: 1),

                            // 1. PERSONAL + PHOTO
                            _header('1. Personal Information'),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            flex: 3,
                                            child: _field('Name', 'name',
                                                validator: Validators.alpha,
                                                formatter:
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'[a-zA-Z\s.,]')))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 3,
                                            child: _field(
                                                'Father Name', 'fatherName',
                                                validator: Validators.alpha,
                                                formatter:
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'[a-zA-Z\s.,]')))),
                                      ]),
                                      const SizedBox(height: rowGap),
                                      Row(children: [
                                        Expanded(
                                            child: _field('DOB', 'dob',
                                                isDate: true)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: _field('Qualification',
                                                'qualification',
                                                validator:
                                                    Validators.alphaNumeric)),
                                      ]),
                                      const SizedBox(height: rowGap),
                                      _dropdown(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _photoBox(),
                              ],
                            ),

                            // 2. IDs
                            _header('2. Identification'),
                            Row(children: [
                              Expanded(
                                  child: _field('Passport', 'passport',
                                      validator: Validators.alphaNumeric)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('License', 'license',
                                      validator: Validators.alphaNumeric)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('Aadhar', 'aadhar',
                                      validator: Validators.numeric,
                                      formatter: FilteringTextInputFormatter
                                          .digitsOnly)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('PAN', 'pan',
                                      validator: Validators.alphaNumeric)),
                            ]),

                            // 3. CONTACT
                            _header('3. Contact Details'),
                            Row(children: [
                              Expanded(
                                  child: _field('Local Addr', 'localAddress')),
                              const SizedBox(width: 8),
                              Expanded(
                                  child:
                                      _field('Perm Addr', 'permanentAddress')),
                            ]),
                            const SizedBox(height: rowGap),
                            Row(children: [
                              Expanded(
                                  child: _field('Mobile', 'mobile',
                                      validator: Validators.phone,
                                      formatter: FilteringTextInputFormatter
                                          .digitsOnly)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('Res. Tel', 'residenceTel',
                                      formatter: FilteringTextInputFormatter
                                          .digitsOnly)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('Email', 'email',
                                      validator: Validators.email)),
                            ]),
                            const SizedBox(height: rowGap),
                            Row(children: [
                              Expanded(
                                  child: _field('Emergency', 'emergencyContact',
                                      formatter: FilteringTextInputFormatter
                                          .digitsOnly)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('Blood Grp', 'bloodGroup')),
                            ]),

                            // 4. BANK
                            _header('4. Bank Details'),
                            Row(children: [
                              Expanded(
                                  child: _field('Bank Name', 'bankName',
                                      validator: Validators.alpha)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('Branch', 'branch',
                                      validator: Validators.alphaNumeric)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('IFSC', 'ifsc',
                                      validator: Validators.alphaNumeric)),
                            ]),
                            const SizedBox(height: rowGap),
                            Row(children: [
                              Expanded(
                                  child: _field('Account Name', 'accountName',
                                      validator: Validators.alpha)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('Account No', 'accountNumber',
                                      validator: Validators.numeric)),
                            ]),

                            // 5. HR (LOCKED FOR EMPLOYEE)
                            _header('5. For HR Use Only'),
                            Row(children: [
                              Expanded(
                                  child: _field('Emp Code', 'empCode',
                                      validator:
                                          Validators.optionalAlphaNumeric,
                                      // LOCKED if it's an Employee (resumeId is null)
                                      locked: isEmployee)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _field('DOJ', 'doj',
                                      isDate: true,
                                      validator: Validators.optional,
                                      // LOCKED if it's an Employee
                                      locked: isEmployee)),
                              const SizedBox(width: 8),
                              Expanded(
                                  flex: 2,
                                  child: _field('Designation', 'designation',
                                      validator:
                                          Validators.optionalAlphaNumeric,
                                      // LOCKED if it's an Employee
                                      locked: isEmployee)),
                            ]),

                            const SizedBox(height: 20),
                            const Text(
                                "I hereby agree and affirm that the above information is true to the best of my knowledge.",
                                style: TextStyle(
                                    fontSize: 12, fontStyle: FontStyle.italic)),

                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Signature of Candidate",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                      Container(
                                          height: 1,
                                          width: 180,
                                          color: Colors.black,
                                          margin:
                                              const EdgeInsets.only(top: 4)),
                                    ]),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Signature of HR Officer:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                      Container(
                                          height: 1,
                                          width: 180,
                                          color: Colors.black,
                                          margin:
                                              const EdgeInsets.only(top: 4)),
                                    ]),
                              ],
                            ),

                            if (!widget.isViewOnly) ...[
                              const SizedBox(height: 20),
                              if (_resultMessage.isNotEmpty)
                                Center(
                                    child: Text(_resultMessage,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold))),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                      onPressed:
                                          _isSubmitting ? null : _submitForm,
                                      child: Text(
                                          _isSubmitting ? '...' : 'SUBMIT')),
                                  const SizedBox(width: 15),
                                  OutlinedButton(
                                    onPressed: () {
                                      _formKey.currentState!.reset();
                                      for (var c in _ctrls.values) c.clear();
                                      _removeImage();
                                      _focusNodes['name']?.requestFocus();
                                    },
                                    style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 48),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        side: const BorderSide(
                                            color: Colors.black),
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero)),
                                    child: const Text('RESET',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
