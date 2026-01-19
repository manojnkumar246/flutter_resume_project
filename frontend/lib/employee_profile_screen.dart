import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'utils.dart';
import 'services/auth_service.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isEditing = false;
  bool _isSubmitting = false;
  String _resultMessage = '';
  bool _isSuccess = false;

  // Original data (for comparison)
  Map<String, dynamic> _originalData = {};

  // Controllers
  final Map<String, TextEditingController> _ctrls = {};
  String _maritalStatus = '';
  Uint8List? _selectedImageBytes;
  String? _originalPhotoBase64;

  // Pending requests
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _loadingRequests = false;

  // Focus Nodes
  final Map<String, FocusNode> _focusNodes = {};

  // Ordered keys for form fields (without password for profile view)
  final List<String> _orderedKeys = [
    'name',
    'fatherName',
    'dob',
    'qualification',
    'maritalStatus',
    'passport',
    'license',
    'aadhar',
    'pan',
    'localAddress',
    'permanentAddress',
    'mobile',
    'residenceTel',
    'email',
    'emergencyContact',
    'bloodGroup',
    'bankName',
    'branch',
    'ifsc',
    'accountName',
    'accountNumber',
    'empCode',
    'doj',
    'designation',
  ];

  // Fields that employee can edit
  final List<String> _editableFields = [
    'localAddress',
    'permanentAddress',
    'mobile',
    'residenceTel',
    'email',
    'emergencyContact',
    'bloodGroup',
    'bankName',
    'branch',
    'ifsc',
    'accountName',
    'accountNumber',
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
    _loadProfileData();
    _loadPendingRequests();
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

  void _loadProfileData() {
    final data = _authService.employeeData;
    if (data != null) {
      _originalData = Map<String, dynamic>.from(data);
      setState(() {
        for (var k in _ctrls.keys) {
          _ctrls[k]!.text = data[k]?.toString() ?? '';
        }
        _maritalStatus = data['maritalStatus'] ?? '';
        _originalPhotoBase64 = data['photoBase64']?.toString();
        if (_originalPhotoBase64 != null && _originalPhotoBase64!.isNotEmpty) {
          try {
            _selectedImageBytes = base64Decode(_originalPhotoBase64!);
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _loadPendingRequests() async {
    if (_authService.employeeId == null) return;

    setState(() => _loadingRequests = true);

    try {
      final response = await http.get(
        Uri.parse(
            '$kBackendBase/profile-requests/employee/${_authService.employeeId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _pendingRequests =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
    } finally {
      setState(() => _loadingRequests = false);
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
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

  void _removeImage() {
    if (!_isEditing) return;
    setState(() => _selectedImageBytes = null);
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    if (!_isEditing) return;
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

  // Get the changes made by employee
  Map<String, dynamic> _getChanges() {
    final changes = <String, dynamic>{};

    for (var key in _editableFields) {
      if (key == 'maritalStatus') continue;

      final newValue = _ctrls[key]?.text ?? '';
      final oldValue = _originalData[key]?.toString() ?? '';

      if (newValue != oldValue) {
        changes[key] = newValue;
      }
    }

    // Check photo change
    final newPhotoBase64 =
        _selectedImageBytes != null ? base64Encode(_selectedImageBytes!) : '';
    if (newPhotoBase64 != (_originalPhotoBase64 ?? '')) {
      changes['photoBase64'] = newPhotoBase64;
    }

    return changes;
  }

  // Get original values for changed fields
  Map<String, dynamic> _getOriginalData(Map<String, dynamic> changes) {
    final original = <String, dynamic>{};
    for (var key in changes.keys) {
      if (key == 'photoBase64') {
        original[key] = '[Photo]';
      } else {
        original[key] = _originalData[key] ?? '';
      }
    }
    return original;
  }

  Future<void> _submitChangeRequest() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fix errors'), backgroundColor: Colors.red),
      );
      return;
    }

    final changes = _getChanges();

    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No changes detected'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Change Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are requesting changes to the following fields:'),
            const SizedBox(height: 12),
            ...changes.keys.map((key) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 16),
                      Text(_getFieldLabel(key),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            const Text(
              'These changes will be sent to Admin for approval.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final requestData = {
        'employeeId': _authService.employeeId,
        'employeeName': _authService.employeeName,
        'employeeEmail': _authService.employeeEmail,
        'changes': changes,
        'originalData': _getOriginalData(changes),
      };

      final response = await http.post(
        Uri.parse('$kBackendBase/profile-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        setState(() {
          _resultMessage =
              'Change request submitted successfully! Waiting for admin approval.';
          _isSuccess = true;
          _isEditing = false;
        });
        // Reload original data and pending requests
        _loadProfileData();
        _loadPendingRequests();
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _resultMessage = error['error'] ?? 'Failed to submit request';
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

  String _getFieldLabel(String key) {
    final labels = {
      'name': 'Full Name',
      'fatherName': "Father's Name",
      'dob': 'Date of Birth',
      'qualification': 'Qualification',
      'maritalStatus': 'Marital Status',
      'passport': 'Passport No.',
      'license': 'Driving License',
      'aadhar': 'Aadhar No.',
      'pan': 'PAN No.',
      'localAddress': 'Local Address',
      'permanentAddress': 'Permanent Address',
      'mobile': 'Mobile',
      'residenceTel': 'Residence Tel.',
      'email': 'Email',
      'emergencyContact': 'Emergency Contact',
      'bloodGroup': 'Blood Group',
      'bankName': 'Bank Name',
      'branch': 'Branch',
      'ifsc': 'IFSC Code',
      'accountName': 'Account Name',
      'accountNumber': 'Account Number',
      'empCode': 'Employee Code',
      'doj': 'Date of Joining',
      'designation': 'Designation',
      'photoBase64': 'Photo',
    };
    return labels[key] ?? key;
  }

  Widget _field(
    String label,
    String key, {
    String? Function(String?)? validator,
    bool isDate = false,
    bool isLocked = false, // Fields employee cannot edit
    TextInputFormatter? formatter,
  }) {
    int orderIndex = _orderedKeys.indexOf(key);
    final canEdit = _isEditing && _editableFields.contains(key) && !isLocked;
    final isReadOnly = !canEdit;

    return FocusTraversalOrder(
      order: NumericFocusOrder(orderIndex.toDouble()),
      child: SizedBox(
        height: 42,
        child: TextFormField(
          controller: _ctrls[key],
          focusNode: _focusNodes[key],
          canRequestFocus: canEdit,
          readOnly: isReadOnly || isDate,
          style: TextStyle(
            fontSize: 13,
            color: isReadOnly ? Colors.black54 : Colors.black,
          ),
          onTap: isDate && canEdit ? () => _selectDate(_ctrls[key]!) : null,
          inputFormatters: formatter != null ? [formatter] : [],
          validator:
              _isEditing && canEdit ? (validator ?? Validators.required) : null,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _focusNext(key),
          decoration: InputDecoration(
            labelText: label,
            fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
            suffixIcon: isDate
                ? const Icon(Icons.calendar_today,
                    size: 14, color: Colors.black)
                : isLocked
                    ? const Icon(Icons.lock, size: 14, color: Colors.grey)
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
          decoration: InputDecoration(
            labelText: 'Marital Status',
            fillColor: Colors.grey[100],
          ),
          items: maritalOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: null, // Always read-only for this field
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
                    if (_isEditing)
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
              : _isEditing
                  ? InkWell(
                      onTap: _pickImage,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 20, color: Colors.black54),
                          SizedBox(height: 4),
                          Text("Add Photo",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black87)),
                        ],
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, size: 40, color: Colors.grey),
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

  Widget _buildPendingRequestsSection() {
    final pendingCount =
        _pendingRequests.where((r) => r['status'] == 'pending').length;

    if (_loadingRequests) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_pendingRequests.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Change Requests',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              if (pendingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingCount Pending',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_pendingRequests
              .take(3)
              .map((request) => _buildRequestItem(request))),
          if (_pendingRequests.length > 3)
            TextButton(
              onPressed: () => _showAllRequests(),
              child: Text('View all ${_pendingRequests.length} requests'),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final createdAt = request['createdAt'] as String?;
    final changes = request['changes'] as Map<String, dynamic>?;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  changes?.keys.map((k) => _getFieldLabel(k)).join(', ') ??
                      'Unknown fields',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                if (status != 'pending' && request['adminComment'] != null)
                  Text(
                    'Admin: ${request['adminComment']}',
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  void _showAllRequests() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'All Change Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) =>
                      _buildRequestItem(_pendingRequests[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PROFILE'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Request Changes',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _authService.refreshEmployeeData().then((_) {
                _loadProfileData();
                _loadPendingRequests();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.85),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
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
                            Icon(
                              _isEditing ? Icons.edit : Icons.person,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditing
                                        ? 'Request Profile Changes'
                                        : 'My Profile',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (!_isEditing)
                                    Text(
                                      'View your personal information',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                  if (_isEditing)
                                    Text(
                                      'Changes will be sent to Admin for approval',
                                      style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            if (_isEditing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'EDITING',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 32, color: Colors.black),

                        // Pending Requests Section
                        _buildPendingRequestsSection(),

                        // Personal Info Section (Read-only)
                        _sectionHeader('Personal Information (Read-Only)'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: _field('Full Name', 'name',
                                            isLocked: true)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _field(
                                            "Father's Name", 'fatherName',
                                            isLocked: true)),
                                  ]),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    Expanded(
                                        child: _field('Date of Birth', 'dob',
                                            isDate: true, isLocked: true)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _field(
                                            'Qualification', 'qualification',
                                            isLocked: true)),
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

                        // ID Documents Section (Read-only)
                        _sectionHeader('ID Documents (Read-Only)'),
                        Row(children: [
                          Expanded(
                              child: _field('Passport No.', 'passport',
                                  isLocked: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Driving License', 'license',
                                  isLocked: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Aadhar No.', 'aadhar',
                                  isLocked: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('PAN No.', 'pan', isLocked: true)),
                        ]),

                        // Address Section (Editable)
                        _sectionHeader(
                            _isEditing ? 'Address (Editable)' : 'Address'),
                        Row(children: [
                          Expanded(
                              child: _field('Local Address', 'localAddress')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field(
                                  'Permanent Address', 'permanentAddress')),
                        ]),

                        // Contact Section (Editable)
                        _sectionHeader(_isEditing
                            ? 'Contact Information (Editable)'
                            : 'Contact Information'),
                        Row(children: [
                          Expanded(
                              child: _field('Mobile', 'mobile',
                                  validator: Validators.phone)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Residence Tel.', 'residenceTel',
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Email', 'email',
                                  validator: Validators.email)),
                        ]),

                        // Emergency & Bank (Editable)
                        _sectionHeader(_isEditing
                            ? 'Emergency & Bank Details (Editable)'
                            : 'Emergency & Bank Details'),
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

                        // HR Fields (Read-only always)
                        _sectionHeader('Employment Details (HR Managed)'),
                        Row(children: [
                          Expanded(
                              child: _field('Employee Code', 'empCode',
                                  isLocked: true,
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Date of Joining', 'doj',
                                  isDate: true,
                                  isLocked: true,
                                  validator: Validators.optional)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field('Designation', 'designation',
                                  isLocked: true,
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
                              onPressed: () {
                                if (_isEditing) {
                                  setState(() {
                                    _isEditing = false;
                                    _resultMessage = '';
                                  });
                                  _loadProfileData(); // Reset to original data
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                              child: Text(_isEditing ? 'CANCEL' : 'BACK'),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed:
                                    _isSubmitting ? null : _submitChangeRequest,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(Icons.send, size: 18),
                                label: const Text('SUBMIT REQUEST'),
                              ),
                            ],
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
