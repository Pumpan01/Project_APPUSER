import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  late Future<List<dynamic>> _announcements;

  @override
  void initState() {
    super.initState();
    _announcements = fetchAnnouncements();
  }

  Future<List<dynamic>> fetchAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.horplus.work/api/announcements'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load announcements');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _refreshAnnouncements() async {
    setState(() {
      _announcements = fetchAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // พื้นหลังโปร่งใส เพื่อให้เห็น Stack ด้านใน
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
          // 2) เนื้อหาหลัก: SafeArea + RefreshIndicator + FutureBuilder
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshAnnouncements,
              color: const Color(0xFFFF8800),
              child: FutureBuilder<List<dynamic>>(
                future: _announcements,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'เกิดข้อผิดพลาด: ${snapshot.error}',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'ไม่มีประกาศ',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  } else {
                    // เพิ่ม padding top: 80 เพื่อเลื่อนการ์ดลงจากขอบบน
                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        top: 135,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 12,
                      ),
                      itemBuilder: (context, index) {
                        final announcement = snapshot.data![index];
                        return _buildNoticeTile(
                          icon: FontAwesomeIcons.bell,
                          title: announcement['title'] ?? 'ไม่มีข้อมูล',
                          subtitle: announcement['detail'] ?? '',
                          date: announcement['created_at'] != null
                              ? announcement['created_at'].split('T')[0]
                              : 'ไม่ทราบวันที่',
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
  }) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Color(0xFFE8CFA8),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ไอคอนวงกลม
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8800).withOpacity(0.1),
              ),
              child: Icon(icon, color: const Color(0xFFFF8800), size: 24),
            ),
            const SizedBox(width: 12),
            // ข้อความประกาศ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'โพสต์เมื่อ: $date',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
