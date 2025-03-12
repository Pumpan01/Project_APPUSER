import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyContactPage extends StatelessWidget {
  const EmergencyContactPage({super.key});

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'ไม่สามารถโทรไปยัง $phoneNumber ได้';
    }
  }

  void _showCallPopup(BuildContext context, String name, String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'โทรหา $name',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'เบอร์โทร: $phoneNumber',
            style: GoogleFonts.prompt(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.prompt(color: Colors.red),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _makePhoneCall(phoneNumber);
              },
              child: Text(
                'โทร',
                style: GoogleFonts.prompt(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ปรับให้ context เป็น named parameter
  Widget _buildEmergencyContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String phoneNumber,
  }) {
    return GestureDetector(
      onTap: () => _showCallPopup(context, title, phoneNumber),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
            color: Color(0xFFE8CFA8),
            width: 1.5,
          ),
        ),
        color: Colors.white,
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.prompt(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.prompt(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ปุ่มโทร
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
                onPressed: () => _showCallPopup(context, title, phoneNumber),
                child: Text(
                  'โทร',
                  style: GoogleFonts.prompt(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // ใช้พื้นหลังโปร่งใส เพื่อให้ Stack ด้านหลังแสดงภาพพื้นหลัง
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // พื้นหลังสีส้ม + รูปภาพเต็มจอ
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
          // เนื้อหาหลัก
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 130, left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // หัวข้อหน้า + ปุ่ม Back
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'เบอร์ติดต่อฉุกเฉิน',
                        style: GoogleFonts.prompt(
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // รายการเบอร์ติดต่อฉุกเฉิน (เลื่อนได้)
                  Expanded(
                    child: ListView(
                      children: [
                        _buildEmergencyContactCard(
                          context: context,
                          icon: Icons.local_police,
                          title: 'ตำรวจ',
                          subtitle: 'โทร 191',
                          color: Colors.blue,
                          phoneNumber: '191',
                        ),
                        _buildEmergencyContactCard(
                          context: context,
                          icon: Icons.local_hospital,
                          title: 'โรงพยาบาล',
                          subtitle: 'โทร 1669',
                          color: Colors.red,
                          phoneNumber: '1669',
                        ),
                        _buildEmergencyContactCard(
                          context: context,
                          icon: Icons.fire_truck,
                          title: 'ดับเพลิง',
                          subtitle: 'โทร 199',
                          color: Colors.orange,
                          phoneNumber: '199',
                        ),
                        _buildEmergencyContactCard(
                          context: context,
                          icon: Icons.support_agent,
                          title: 'กู้ภัย',
                          subtitle: 'โทร 1554',
                          color: Colors.green,
                          phoneNumber: '1554',
                        ),
                        _buildEmergencyContactCard(
                          context: context,
                          icon: Icons.phone,
                          title: 'เจ้าของหอพัก',
                          subtitle: 'โทร 089-123-4567',
                          color: Colors.purple,
                          phoneNumber: '089-123-4567',
                        ),
                      ],
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
}
