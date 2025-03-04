import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myproject/UI/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // 🌟 แสดง Popup แจ้งเตือน
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // 🔒 ฟังก์ชันล็อกอิน
  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorPopup('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('http://10.0.2.2:4000/api/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'เข้าสู่ระบบสำเร็จ') {
          final userId = data['user']['user_id'] as int;
          final roomNumber = data['user']['room_number'] ?? 0;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                userId: userId,
                roomNumber: roomNumber,
              ),
            ),
          );
        } else {
          _showErrorPopup(data['error'] ?? 'เกิดข้อผิดพลาด');
        }
      } else if (response.statusCode == 401) {
        _showErrorPopup('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
      } else {
        _showErrorPopup('เกิดข้อผิดพลาดในเซิร์ฟเวอร์');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorPopup('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎨 พื้นหลังลวดลาย
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("images/background_pattern.png"),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
              color: Colors.orange.shade50,
            ),
          ),

          // 📝 เนื้อหาหลัก
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/logohorplus.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 30),

                  // 🏠 การ์ดป้อนข้อมูล
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Username',
                            icon: Icons.person_outline,
                            isPassword: false,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 30),
                          _buildLoginButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏆 ปุ่มล็อกอิน
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8800),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
    );
  }

  // 🔑 TextField กรอกข้อมูล
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE8CFA8)),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFFF8800)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFFF8800),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }
}
