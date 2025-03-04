import 'package:flutter/material.dart';
import 'login.dart'; // นำเข้าไฟล์ login.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dorm Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
          secondary: const Color(0xFF9E9E9E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(), // ตั้งค่าให้หน้าเริ่มต้นเป็น LoginPage
    );
  }
}
