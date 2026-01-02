import 'package:flutter/material.dart';

import 'home_screen.dart';

void main() => runApp(const PersonalDataApp());

class PersonalDataApp extends StatelessWidget {
  const PersonalDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HR Portal',
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
      home: const HomeScreen(),
    );
  }
}