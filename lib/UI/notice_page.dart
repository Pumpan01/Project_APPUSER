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
      final response =
          await http.get(Uri.parse('http://10.0.2.2:4000/api/announcements'));

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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // ✅ เปลี่ยนพื้นหลังเป็นสีพีชอ่อน
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8800), // ✅ สีส้มสด
        elevation: 0,
        centerTitle: true,
        title: Text(
          'การแจ้งเตือน',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAnnouncements,
        color: const Color(0xFFFF8800), // ✅ สีรีเฟรช
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Color(0xFFE8CFA8), // ✅ เส้นแบ่งสีเบจ
                    thickness: 1.2,
                    height: 20,
                  ),
                  itemBuilder: (context, index) {
                    final announcement = snapshot.data![index];
                    return _buildNoticeTile(
                      icon: FontAwesomeIcons.bell,
                      title: announcement['title'],
                      subtitle: announcement['detail'],
                      date: announcement['created_at'] != null
                          ? announcement['created_at'].split('T')[0]
                          : 'ไม่ทราบวันที่',
                      context: context,
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required BuildContext context,
  }) {
    return Card(
      color: Colors.white, // ✅ เปลี่ยนสีการ์ดเป็นสีขาว
      elevation: 4, // ✅ เพิ่มเงาให้ดูมีมิติ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE8CFA8), // ✅ ขอบสีเบจอ่อน
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8800).withOpacity(0.1),
              ),
              child: Icon(icon, color: const Color(0xFFFF8800), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'โพสต์เมื่อ: $date',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF777777), // ✅ สีเทาอ่อน
                          ),
                        ),
                      ),
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
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
