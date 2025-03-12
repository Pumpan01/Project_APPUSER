import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../login.dart';

class ProfilePage extends StatefulWidget {
  final int userId; // รับ userId จากหน้า HomePage

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData; // ข้อมูลผู้ใช้
  bool _isLoading = true; // สถานะการโหลด

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // ดึงข้อมูลผู้ใช้เมื่อเปิดหน้า
  }

  // ฟังก์ชันดึงข้อมูลผู้ใช้จาก API
  Future<void> _fetchUserData() async {
    final url = Uri.parse('https://api.horplus.work/api/users/${widget.userId}');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _userData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        debugPrint('Error fetching user data: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // สำหรับการกำหนดพื้นหลังเต็มจอ

    return Scaffold(
      // พื้นหลังโปร่งใส (เพื่อให้เห็น Container พื้นหลังใน Stack)
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1) พื้นหลังสีส้ม + รูปภาพเต็มจอ
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8800),
              image: const DecorationImage(
                image: AssetImage("images/backgroundmain.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2) เนื้อหาหลัก
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _userData == null
                    ? const Center(
                        child: Text(
                          'ไม่พบข้อมูลผู้ใช้',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          // เพิ่มระยะห่างด้านบนด้วย top: 50 หรือปรับตามต้องการ
                          padding: const EdgeInsets.only(
                            top: 150,
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ✅ การ์ดข้อมูลห้องพัก
                              Card(
                                color: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(
                                    color: Color(0xFFE8CFA8), // ✅ ขอบสีเบจอ่อน
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ข้อมูลผู้เช่า',
                                        style: GoogleFonts.poppins(
                                          textStyle: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF8800),
                                          ),
                                        ),
                                      ),
                                      const Divider(
                                        color: Color(0xFFFF8800),
                                        thickness: 1.5,
                                        height: 20,
                                      ),
                                      const SizedBox(height: 10),
                                      // ✅ ข้อมูลผู้เช่า (แสดงข้อมูลจาก API)
                                      _buildInfoRow(
                                        label: 'ชื่อเต็ม',
                                        value: _userData?['full_name']
                                                ?.toString() ??
                                            'ไม่พบข้อมูล',
                                        icon: FontAwesomeIcons.user,
                                      ),
                                      _buildInfoRow(
                                        label: 'เบอร์โทรศัพท์',
                                        value: _userData?['phone_number']
                                                ?.toString() ??
                                            'ไม่พบข้อมูล',
                                        icon: FontAwesomeIcons.phone,
                                      ),
                                      _buildInfoRow(
                                        label: 'ห้องพัก',
                                        value: _userData?['room_number']
                                                ?.toString() ??
                                            'ไม่พบข้อมูล',
                                        icon: FontAwesomeIcons.doorClosed,
                                      ),
                                      _buildInfoRow(
                                        label: 'Line ID',
                                        value: _userData?['line_id']
                                                ?.toString() ??
                                            'ไม่พบข้อมูล',
                                        icon: FontAwesomeIcons.line,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // เพิ่มระยะห่างระหว่าง Card กับปุ่ม
                              const SizedBox(height: 40),

                              // ✅ ปุ่ม "ออกจากระบบ"
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 80,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  shadowColor: Colors.redAccent,
                                  elevation: 5,
                                ),
                                icon: const Icon(
                                  FontAwesomeIcons.signOutAlt,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'ออกจากระบบ',
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ✅ ฟังก์ชันช่วยสร้างแถวข้อมูลผู้เช่าแต่ละรายการ
  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8800), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
