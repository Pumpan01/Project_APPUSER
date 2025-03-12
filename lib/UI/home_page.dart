import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'notice_page.dart';
import 'profile.dart';
import 'report_repairs_page.dart';
import 'water_bill_page.dart';
import 'payment_history_page.dart';
import 'emergency_contact_page.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final int roomNumber;

  const HomePage({
    super.key,
    required this.userId,
    required this.roomNumber,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            selectedItemColor: const Color(0xFFFF8800),
            unselectedItemColor: Colors.black54,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.bell),
                label: 'แจ้งเตือน',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.house),
                label: 'หน้าแรก',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.user),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // พื้นหลังสีส้ม + รูปภาพเต็มจอ
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8800), // สีพื้นหลังส้ม
              image: const DecorationImage(
                image: AssetImage("images/backgroundmain.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // เนื้อหาหลัก (IndexedStack)
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: _currentIndex,
                  children: [
                    const NoticePage(),
                    HomeContent(
                      userId: widget.userId,
                      roomNumber: widget.roomNumber,
                    ),
                    ProfilePage(userId: widget.userId),
                  ],
                ),
        ],
      ),
    );
  }
}

// ===========================
// HomeContent: เนื้อหาหลัก
// ===========================
class HomeContent extends StatelessWidget {
  final int userId;
  final int roomNumber;

  const HomeContent({
    super.key,
    required this.userId,
    required this.roomNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ตั้งค่าสีพื้นหลังเป็นโปร่งใส เพื่อให้เห็นพื้นหลังของ HomePage
      backgroundColor: Colors.transparent,
      body: Center(
        // ใช้ Center เพื่อให้คอนเทนต์อยู่กึ่งกลางจอ
        child: SingleChildScrollView(
          // หาก GridView มีเนื้อหามาก สามารถเลื่อนใน ScrollView ได้
          child: ConstrainedBox(
            // จำกัดความกว้างสูงสุด ไม่ให้ใหญ่เกินไปบนแท็บเล็ต
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85,
                children: [
                  _buildMenuButton(
                    context,
                    icon: FontAwesomeIcons.fileInvoiceDollar,
                    title: 'บิลค่าน้ำค่าไฟ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WaterBillPage(userId: userId),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    context,
                    icon: FontAwesomeIcons.clockRotateLeft,
                    title: 'ประวัติการชำระ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentHistoryPage(userId: userId),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    context,
                    icon: FontAwesomeIcons.screwdriverWrench,
                    title: 'แจ้งซ่อม',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportRepairsPage(
                            userId: userId,
                            roomNumber: roomNumber,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    context,
                    icon: FontAwesomeIcons.phone,
                    title: 'เบอร์ติดต่อฉุกเฉิน',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE8CFA8),
            width: 1.5, // ปรับให้บางลงเล็กน้อย
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07), // ลดเงาให้เบาลง
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: const Color(0xFFFF6B00)),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
