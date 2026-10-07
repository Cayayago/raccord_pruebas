import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'profile_screen.dart';
import 'forgot_password_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raccord',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const ForgotPasswordScreen(),
    );
  }
}