import 'package:flutter/material.dart';

// --- CONFIGURATION ---
const String kBackendBase = 'http://192.168.55.105:3000';

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
Widget buildBackground({double overlayOpacity = 0.0}) {
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
AppBar buildAppBar(String title, {List<Widget>? actions, Widget? customTitle}) {
  return AppBar(
    title: customTitle ?? Text(title.toUpperCase()),
    actions: actions,
    bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.black, height: 1.0)),
  );
}
