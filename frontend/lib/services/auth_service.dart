import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils.dart';

/// A singleton service to manage employee authentication state
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Current logged-in employee data
  Map<String, dynamic>? _employeeData;
  String? _employeeId;
  bool _isLoggedIn = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get employeeId => _employeeId;
  Map<String, dynamic>? get employeeData => _employeeData;

  // Get specific employee fields
  String get employeeName => _employeeData?['name'] ?? '';
  String get employeeEmail => _employeeData?['email'] ?? '';
  String get employeeCode => _employeeData?['empCode'] ?? '';
  String get employeeMobile => _employeeData?['mobile'] ?? '';
  String get employeeDesignation => _employeeData?['designation'] ?? '';

  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$kBackendBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _employeeData = data['employee'];
        _employeeId = data['employee']['id'];
        _isLoggedIn = true;
        notifyListeners();
        return {'success': true, 'message': 'Login successful'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Register new employee (same as personal data form + password)
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$kBackendBase/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return {'success': true, 'message': 'Registration successful', 'id': result['id']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Update employee data after profile edit
  Future<void> refreshEmployeeData() async {
    if (_employeeId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$kBackendBase/resumes/$_employeeId'),
      );
      
      if (response.statusCode == 200) {
        _employeeData = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing employee data: $e');
    }
  }

  /// Logout
  void logout() {
    _employeeData = null;
    _employeeId = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
