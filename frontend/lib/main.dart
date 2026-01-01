import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

// --- CONFIGURATION ---
const String kBackendBase = 'http://10.10.7.181:3000';

void main() => runApp(const PersonalDataApp());

// --- ROOT WIDGET ---
class PersonalDataApp extends StatelessWidget {
  const PersonalDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Data Form',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'serif',
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.transparent,
        visualDensity: VisualDensity.standard,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 14, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 13, color: Colors.black),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          labelStyle: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
          errorStyle: TextStyle(height: 0, fontSize: 0),
          border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 0.5),
              borderRadius: BorderRadius.zero),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black54, width: 0.5),
              borderRadius: BorderRadius.zero),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.zero),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.0),
              borderRadius: BorderRadius.zero),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            textStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 13),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          centerTitle: true,
          toolbarHeight: 45,
          titleTextStyle: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black, size: 22),
        ),
      ),
      home: const PersonalDataForm(),
    );
  }
}

// --- VALIDATORS ---
class Validators {
  static String? required(String? v) => v?.isEmpty ?? true ? 'Required' : null;

  static String? alpha(String? v) =>
      v != null && RegExp(r'^[a-zA-Z\s.,]+$').hasMatch(v)
          ? null
          : 'Letters only';

  static String? numeric(String? v) =>
      v != null && RegExp(r'^[0-9]+$').hasMatch(v) ? null : 'Numbers only';

  static String? alphaNumeric(String? v) =>
      v != null && RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(v)
          ? null
          : 'Alphanumeric';

  static String? email(String? v) =>
      v != null && v.contains('@') ? null : 'Invalid Email';

  static String? phone(String? v) =>
      v != null && v.length == 10 ? null : '10 Digits';

  // --- OPTIONAL VALIDATORS (For HR Fields) ---
  static String? optional(String? v) => null;

  static String? optionalAlphaNumeric(String? v) {
    if (v == null || v.isEmpty) return null;
    return RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(v) ? null : 'Alphanumeric';
  }
}

// --- HELPERS ---
Widget _buildBackground({double overlayOpacity = 0.0}) {
  return Stack(
    children: [
      Positioned.fill(
        child: Image.asset(
          'assets/images/back_ground.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.white),
        ),
      ),
      Positioned.fill(
          child: Container(color: Colors.white.withOpacity(overlayOpacity))),
    ],
  );
}

// Updated Helper to support Custom Title (Search Bar)
AppBar _buildAppBar(String title,
    {List<Widget>? actions, Widget? customTitle}) {
  return AppBar(
    title: customTitle ?? Text(title.toUpperCase()),
    actions: actions,
    bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.black, height: 1.0)),
  );
}

// --- FORM SCREEN ---
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
      appBar: _buildAppBar(
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
            _buildBackground(),
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

// --- ADMIN LOGIN SCREEN ---
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
          context, MaterialPageRoute(builder: (_) => const ResumeListScreen()));
    } else {
      setState(() => _err = 'Invalid credentials');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar('Admin Login'),
      body: Stack(
        children: [
          _buildBackground(),
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

// --- RESUME LIST SCREEN (WITH SEARCH) ---
class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key});
  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  // Holds the full data from server
  List<dynamic> _allResumes = [];
  // Holds the data currently visible (filtered)
  List<dynamic> _filteredResumes = [];

  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('$kBackendBase/resumes'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _allResumes = data;
          _filteredResumes = data; // Initially, filtered list = all list
        });
      }
    } catch (_) {}
  }

  // Search Logic
  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      // If the search field is empty, show all users
      results = _allResumes;
    } else {
      // Filter list by name (case insensitive)
      results = _allResumes
          .where((user) => user["name"]
              .toString()
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredResumes = results;
    });
  }

  Future<void> _del(String id) async {
    try {
      final res = await http.delete(Uri.parse('$kBackendBase/resumes/$id'));
      if (res.statusCode == 200) {
        // Reload data to ensure sync with server
        _load();
        // Clear search to avoid confusion or re-run filter
        _searchCtrl.clear();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
        'Resumes',
        // Replace the default title widget if searching
        customTitle: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search Name...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) => _runFilter(value),
              )
            : null,
        actions: [
          // Search Toggle Button
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  // Closing search: clear text and reset list
                  _isSearching = false;
                  _searchCtrl.clear();
                  _filteredResumes = _allResumes;
                } else {
                  // Opening search
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(overlayOpacity: 0.8),
          Column(
            children: [
              // Optional: Show count of results found
              if (_isSearching)
                Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Text(
                    "Found ${_filteredResumes.length} result(s)",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

              Expanded(
                child: _filteredResumes.isEmpty
                    ? const Center(child: Text("No employees found"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        // Use filtered list count
                        itemCount: _filteredResumes.length,
                        itemBuilder: (ctx, i) {
                          // Use filtered list item
                          final r = _filteredResumes[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              title: Text(r['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              subtitle: Text('ID: ${r['id']}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => PersonalDataForm(
                                                  resumeId: r['id'],
                                                  isViewOnly: true)))),
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      PersonalDataForm(
                                                          resumeId: r['id'])))
                                          .then((_) => _load())),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _del(r['id'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
