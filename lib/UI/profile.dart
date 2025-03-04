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
    final url = Uri.parse('http://10.0.2.2:4000/api/users/${widget.userId}');
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // ✅ เปลี่ยนพื้นหลังเป็นสีพีชอ่อน
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8800), // ✅ สีส้มสด
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ข้อมูลห้องพัก',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Loading state
          : _userData == null
              ? const Center(
                  child: Text(
                    'ไม่พบข้อมูลผู้ใช้',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ✅ การ์ดข้อมูลห้องพัก
                        Card(
                          color: Colors.white,
                          elevation: 4, // ✅ เพิ่มเงาให้ดูมีมิติ
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ข้อมูลผู้เช่า',
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF8800)),
                                  ),
                                ),
                                const Divider(
                                  color: Color(0xFFFF8800), // ✅ เส้นแบ่งสีส้ม
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
                        const SizedBox(height: 40),

                        // ✅ ปุ่ม "ออกจากระบบ"
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            shadowColor: Colors.redAccent,
                            elevation: 5,
                          ),
                          icon: const Icon(FontAwesomeIcons.signOutAlt,
                              color: Colors.white),
                          label: Text(
                            'ออกจากระบบ',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                  fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ✅ ฟังก์ชันช่วยสร้างแถวข้อมูลผู้เช่าแต่ละรายการ
  Widget _buildInfoRow(
      {required String label, required String value, required IconData icon}) {
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
                        color: Colors.grey),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
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
