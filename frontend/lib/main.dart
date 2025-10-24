import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';

void main() {
  runApp(const PersonalDataApp());
}

class PersonalDataApp extends StatelessWidget {
  const PersonalDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Data Form',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.indigo,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            shadowColor: Colors.indigoAccent.withOpacity(0.4),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.indigoAccent.withOpacity(0.3),
        ),
      ),
      home: const PersonalDataForm(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  // Hardcoded admin credentials for simplicity
  final String adminUsername = 'admin';
  final String adminPassword = 'password';

  void _login() {
    if (_usernameController.text == adminUsername &&
        _passwordController.text == adminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResumeListScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.indigoAccent.withOpacity(0.4),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Colors.indigoAccent,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.95),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Colors.indigoAccent,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.95),
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _login,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key});

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  final String backendBase = "http://192.168.55.106:3000";
  List<dynamic> resumes = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchResumes();
  }

  Future<void> _fetchResumes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$backendBase/resumes'));
      if (response.statusCode == 200) {
        setState(() {
          resumes = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load resumes: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching resumes: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteResume(String id) async {
    try {
      final response = await http.delete(Uri.parse('$backendBase/resumes/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Resume deleted successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _fetchResumes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete resume: ${response.statusCode}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting resume: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume List'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.indigoAccent.withOpacity(0.4),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : resumes.isEmpty
            ? const Center(child: Text('No resumes found'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: resumes.length,
                itemBuilder: (context, index) {
                  final resume = resumes[index];
                  return FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Card(
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          resume['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Created: ${resume['createdAt']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PersonalDataForm(
                                      resumeId: resume['id'],
                                    ),
                                  ),
                                ).then((_) => _fetchResumes());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                      'Are you sure you want to delete this resume?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  _deleteResume(resume['id']);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonalDataForm(
                                resumeId: resume['id'],
                                isViewOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class PersonalDataForm extends StatefulWidget {
  final String? resumeId;
  final bool isViewOnly;
  final http.Client? client;

  const PersonalDataForm({
    super.key,
    this.resumeId,
    this.isViewOnly = false,
    this.client,
  });

  @override
  State<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends State<PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _resultMessage = '';

  final String backendBase = "http://192.168.55.106:3000";

  // Controllers
  final name = TextEditingController();
  final fatherName = TextEditingController();
  final qualification = TextEditingController();
  final dob = TextEditingController();
  final maritalStatus = TextEditingController();
  final passport = TextEditingController();
  final license = TextEditingController();
  final aadhar = TextEditingController();
  final pan = TextEditingController();
  final localAddress = TextEditingController();
  final permanentAddress = TextEditingController();
  final residenceTel = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final emergencyContact = TextEditingController();
  final bloodGroup = TextEditingController();
  final bankName = TextEditingController();
  final branch = TextEditingController();
  final accountName = TextEditingController();
  final accountNumber = TextEditingController();
  final ifsc = TextEditingController();
  final empCode = TextEditingController();
  final doj = TextEditingController();
  final designation = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.resumeId != null) {
      _fetchResume();
    }
  }

  Future<void> _fetchResume() async {
    try {
      final response = await (widget.client ?? http.Client()).get(
        Uri.parse('$backendBase/resumes/${widget.resumeId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          name.text = data['name'] ?? '';
          fatherName.text = data['fatherName'] ?? '';
          qualification.text = data['qualification'] ?? '';
          dob.text = data['dob'] ?? '';
          maritalStatus.text = data['maritalStatus'] ?? '';
          passport.text = data['passport'] ?? '';
          license.text = data['license'] ?? '';
          aadhar.text = data['aadhar'] ?? '';
          pan.text = data['pan'] ?? '';
          localAddress.text = data['localAddress'] ?? '';
          permanentAddress.text = data['permanentAddress'] ?? '';
          residenceTel.text = data['residenceTel'] ?? '';
          mobile.text = data['mobile'] ?? '';
          email.text = data['email'] ?? '';
          emergencyContact.text = data['emergencyContact'] ?? '';
          bloodGroup.text = data['bloodGroup'] ?? '';
          bankName.text = data['bankName'] ?? '';
          branch.text = data['branch'] ?? '';
          accountName.text = data['accountName'] ?? '';
          accountNumber.text = data['accountNumber'] ?? '';
          ifsc.text = data['ifsc'] ?? '';
          empCode.text = data['empCode'] ?? '';
          doj.text = data['doj'] ?? '';
          designation.text = data['designation'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load resume: ${response.statusCode}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading resume: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in [
      name,
      fatherName,
      qualification,
      dob,
      maritalStatus,
      passport,
      license,
      aadhar,
      pan,
      localAddress,
      permanentAddress,
      residenceTel,
      mobile,
      email,
      emergencyContact,
      bloodGroup,
      bankName,
      branch,
      accountName,
      accountNumber,
      ifsc,
      empCode,
      doj,
      designation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _resultMessage = '';
    });

    final data = {
      "name": name.text,
      "fatherName": fatherName.text,
      "qualification": qualification.text,
      "dob": dob.text,
      "maritalStatus": maritalStatus.text,
      "passport": passport.text,
      "license": license.text,
      "aadhar": aadhar.text,
      "pan": pan.text,
      "localAddress": localAddress.text,
      "permanentAddress": permanentAddress.text,
      "residenceTel": residenceTel.text,
      "mobile": mobile.text,
      "email": email.text,
      "emergencyContact": emergencyContact.text,
      "bloodGroup": bloodGroup.text,
      "bankName": bankName.text,
      "branch": branch.text,
      "accountName": accountName.text,
      "accountNumber": accountNumber.text,
      "ifsc": ifsc.text,
      "empCode": empCode.text,
      "doj": doj.text,
      "designation": designation.text,
    };

    try {
      final client = widget.client ?? http.Client();
      final url = widget.resumeId == null
          ? Uri.parse("$backendBase/resume")
          : Uri.parse("$backendBase/resumes/${widget.resumeId}");
      final response = await (widget.resumeId == null
          ? client.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(data),
            )
          : client.put(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(data),
            ));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _resultMessage = widget.resumeId == null
              ? "Form submitted successfully! ID: ${body['id']}"
              : "Form updated successfully!";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_resultMessage),
            backgroundColor: Colors.green.shade600,
          ),
        );
        if (widget.resumeId == null) {
          _formKey.currentState!.reset();
          for (var c in [
            name,
            fatherName,
            qualification,
            dob,
            maritalStatus,
            passport,
            license,
            aadhar,
            pan,
            localAddress,
            permanentAddress,
            residenceTel,
            mobile,
            email,
            emergencyContact,
            bloodGroup,
            bankName,
            branch,
            accountName,
            accountNumber,
            ifsc,
            empCode,
            doj,
            designation,
          ]) {
            c.clear();
          }
        }
      } else {
        setState(() {
          _resultMessage = "Error: ${response.statusCode} ${response.body}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_resultMessage),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _resultMessage = "Request failed: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_resultMessage),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: widget.isViewOnly,
          validator: (value) =>
              value == null || value.isEmpty ? 'Please enter $label' : null,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.95),
            prefixIcon: Icon(
              _getIconForField(label),
              color: Colors.indigoAccent,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForField(String label) {
    switch (label) {
      case 'Name (Mr/Mrs/Miss)':
        return Icons.person;
      case "Father's / Husband's Name":
        return Icons.family_restroom;
      case 'Qualification':
        return Icons.school;
      case 'Date & Time of Birth':
        return Icons.cake;
      case 'Marital Status & No. of Children':
        return Icons.favorite;
      case 'Passport #':
        return Icons.flight;
      case 'Driver’s License #':
        return Icons.drive_eta;
      case 'Aadhar #':
      case 'PAN #':
        return Icons.badge;
      case 'Local Address':
      case 'Permanent Address':
        return Icons.home;
      case 'Residence Telephone':
      case 'Mobile':
      case 'Emergency Contact':
        return Icons.phone;
      case 'Email ID':
        return Icons.email;
      case 'Blood Group':
        return Icons.medical_services;
      case 'Bank Name':
      case 'Branch':
      case 'Account Name':
      case 'Account Number':
      case 'IFSC Code':
        return Icons.account_balance;
      case 'Employee Code Assigned':
        return Icons.code;
      case 'Date of Joining (DD-MM-YYYY)':
        return Icons.calendar_today;
      case 'Designation as on DOJ':
        return Icons.work;
      default:
        return Icons.text_fields;
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigoAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.indigoAccent.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isViewOnly
              ? 'View Resume'
              : widget.resumeId == null
              ? 'Personal Data Form'
              : 'Edit Resume',
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.indigoAccent.withOpacity(0.4),
        actions: [
          if (!widget.isViewOnly && widget.resumeId == null)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              tooltip: 'Admin Login',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: _buildCard(
                    child: Column(
                      children: [
                        _buildSectionTitle(
                          'Personal Information',
                          Icons.person,
                        ),
                        _buildTextField('Name (Mr/Mrs/Miss)', name),
                        _buildTextField(
                          "Father's / Husband's Name",
                          fatherName,
                        ),
                        _buildTextField('Qualification', qualification),
                        _buildTextField('Date & Time of Birth', dob),
                        _buildTextField(
                          'Marital Status & No. of Children',
                          maritalStatus,
                        ),
                      ],
                    ),
                  ),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildCard(
                    child: Column(
                      children: [
                        _buildSectionTitle(
                          'Identification Details',
                          Icons.badge,
                        ),
                        _buildTextField('Passport #', passport),
                        _buildTextField('Driver’s License #', license),
                        _buildTextField('Aadhar #', aadhar),
                        _buildTextField('PAN #', pan),
                      ],
                    ),
                  ),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: _buildCard(
                    child: Column(
                      children: [
                        _buildSectionTitle(
                          'Contact Details',
                          Icons.contact_phone,
                        ),
                        _buildTextField(
                          'Local Address',
                          localAddress,
                          maxLines: 2,
                        ),
                        _buildTextField(
                          'Permanent Address',
                          permanentAddress,
                          maxLines: 2,
                        ),
                        _buildTextField('Residence Telephone', residenceTel),
                        _buildTextField('Mobile', mobile),
                        _buildTextField('Email ID', email),
                        _buildTextField('Emergency Contact', emergencyContact),
                        _buildTextField('Blood Group', bloodGroup),
                      ],
                    ),
                  ),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: _buildCard(
                    child: Column(
                      children: [
                        _buildSectionTitle(
                          'Bank Account Details',
                          Icons.account_balance,
                        ),
                        _buildTextField('Bank Name', bankName),
                        _buildTextField('Branch', branch),
                        _buildTextField('Account Name', accountName),
                        _buildTextField('Account Number', accountNumber),
                        _buildTextField('IFSC Code', ifsc),
                      ],
                    ),
                  ),
                ),
                FadeInDown(
                  duration: const Duration(milliseconds: 900),
                  child: _buildCard(
                    child: Column(
                      children: [
                        _buildSectionTitle(
                          'HR Use Only',
                          Icons.business_center,
                        ),
                        _buildTextField('Employee Code Assigned', empCode),
                        _buildTextField('Date of Joining (DD-MM-YYYY)', doj),
                        _buildTextField('Designation as on DOJ', designation),
                      ],
                    ),
                  ),
                ),
                if (!widget.isViewOnly) ...[
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isSubmitting
                                ? 'Submitting...'
                                : widget.resumeId == null
                                ? 'Submit'
                                : 'Update',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submitForm,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            _formKey.currentState!.reset();
                            for (var c in [
                              name,
                              fatherName,
                              qualification,
                              dob,
                              maritalStatus,
                              passport,
                              license,
                              aadhar,
                              pan,
                              localAddress,
                              permanentAddress,
                              residenceTel,
                              mobile,
                              email,
                              emergencyContact,
                              bloodGroup,
                              bankName,
                              branch,
                              accountName,
                              accountNumber,
                              ifsc,
                              empCode,
                              doj,
                              designation,
                            ]) {
                              c.clear();
                            }
                            setState(() {
                              _resultMessage = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (_resultMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Card(
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _resultMessage,
                          style: TextStyle(
                            color: _resultMessage.contains('Error')
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
