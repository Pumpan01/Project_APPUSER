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

    final url = Uri.parse('https://api.horplus.work/api/login');
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
    final size =
        MediaQuery.of(context).size; // ใช้ MediaQuery เพื่อให้ responsive

    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลังลวดลาย (ภาพมีส่วนบนเป็นสีส้ม ส่วนล่างเป็นสีขาว)
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: Color(0xFFFF8800), // สีพื้นหลังส้ม
              image: const DecorationImage(
                image: AssetImage("images/background_pattern.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // เนื้อหาหลักเลื่อนใน ScrollView
          SingleChildScrollView(
            child: Column(
              children: [
                // เว้นพื้นที่ด้านบน ~40% ของจอ (ปรับมาก/น้อยตามต้องการ)
                SizedBox(height: size.height * 0.4),

                // โซนฟอร์มในส่วนสีขาว
                Center(
                  child: Column(
                    children: [
                      // โลโก้
                      Image.asset(
                        'images/logohorplus.png', // ใส่ path รูปโลโก้
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 40),

                      // TextField Username
                      _buildTextFieldContainer(
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'USERNAME',
                          icon: Icons.account_circle,
                          isPassword: false,
                        ),
                        width: size.width * 0.8,
                      ),
                      const SizedBox(height: 20),

                      // TextField Password
                      _buildTextFieldContainer(
                        child: _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        width: size.width * 0.8,
                      ),
                      const SizedBox(height: 30),

                      // ปุ่ม Login
                      _buildLoginButton(size.width),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📦 Container ช่วยกำหนดความกว้างของ TextField
  Widget _buildTextFieldContainer(
      {required Widget child, required double width}) {
    return SizedBox(
      width: width,
      child: child,
    );
  }

  // 🏆 ปุ่มล็อกอิน
  Widget _buildLoginButton(double screenWidth) {
    return SizedBox(
      width: screenWidth * 0.5,
      height: 45,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : const Text(
                'Login',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
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
        hintText: label,
        prefixIcon: Icon(icon, color: Colors.orange.shade800),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.orange.shade800,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }
}
