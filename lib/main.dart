import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PerfectShotApp());
}

class PerfectShotApp extends StatelessWidget {
  const PerfectShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfect Shot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
