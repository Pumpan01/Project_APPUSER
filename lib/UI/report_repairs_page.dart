import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home_page.dart';

class ReportRepairsPage extends StatefulWidget {
  final int userId;
  final int roomNumber;

  const ReportRepairsPage({
    Key? key,
    required this.userId,
    required this.roomNumber,
  }) : super(key: key);

  @override
  _ReportRepairsPageState createState() => _ReportRepairsPageState();
}

class _ReportRepairsPageState extends State<ReportRepairsPage> {
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  List<dynamic> _repairList = [];

  @override
  void initState() {
    super.initState();
    _fetchRepairList();
  }

  Future<void> _fetchRepairList() async {
    if (!mounted) return; // ป้องกัน context หาย
    final url = Uri.parse('https://api.horplus.work/api/repairs/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _repairList = json.decode(response.body);
        });
      } else {
        debugPrint('Error fetching repair list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _submitReport() async {
    if (_detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรายละเอียดปัญหา')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final url = Uri.parse('https://api.horplus.work/api/repairs');
    final body = {
      "user_id": widget.userId,
      "room_number": widget.roomNumber,
      "description": _detailsController.text,
      "status": "รอดำเนินการ",
      "repair_date": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        _showSuccessPopup(context);
        _detailsController.clear();
        _fetchRepairList();
      } else {
        final error = json.decode(response.body)['error'] ?? 'เกิดข้อผิดพลาด';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteReport(int repairId) async {
    final url = Uri.parse("https://api.horplus.work/api/repairs/$repairId");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบการแจ้งซ่อมสำเร็จ')),
        );
        _fetchRepairList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถลบการแจ้งซ่อมได้')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
      );
    }
  }

  Future<void> _showSuccessPopup(BuildContext context) async {
    if (!mounted) return; // ป้องกัน context หาย
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(
            child: Text(
              'ส่งเรื่องเรียบร้อย',
              style: GoogleFonts.prompt(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8800),
                ),
              ),
            ),
          ),
          content: const Text(
            'การแจ้งของคุณได้ถูกส่งเรียบร้อยแล้ว',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                child: Text(
                  'ตกลง',
                  style: GoogleFonts.prompt(color: Color(0xFFFF8800)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int repairId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "ยืนยันการลบ",
            style: GoogleFonts.prompt(
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          content: Text(
            "คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?",
            style: GoogleFonts.prompt(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "ยกเลิก",
                style: GoogleFonts.prompt(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReport(repairId);
              },
              child: Text("ลบ", style: GoogleFonts.prompt(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // กำหนดสีของสถานะ
  Color _getStatusColor(String? status) {
    switch (status?.trim()) {
      case 'เสร็จสิ้น':
        return Colors.green;
      case 'กำลังดำเนินการ':
        return Colors.blue;
      case 'รอดำเนินการ':
        return Colors.red;
      case 'รอรับเรื่อง':
        return const Color(0xFFFF8800);
      default:
        return Colors.grey;
    }
  }

  // วาดกล่องหัวข้อ
  Widget _buildTitleBox(String title) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF8800), width: 2),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Text(
        title,
        style: GoogleFonts.prompt(
          textStyle: const TextStyle(fontSize: 16, color: Color(0xFFFF8800)),
        ),
      ),
    );
  }

  // แสดงรายการแจ้งซ่อม
  Widget _buildRepairList() {
    if (_repairList.isEmpty) {
      return const Center(child: Text('ไม่มีรายการแจ้งซ่อม'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _repairList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final repair = _repairList[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // บรรทัดแรก: description + ปุ่มลบ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      repair['description'] ?? 'ไม่มีข้อมูล',
                      style: GoogleFonts.prompt(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 26),
                    onPressed: () => _confirmDelete(repair['repair_id']),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // วันที่แจ้ง
              Row(
                children: [
                  Icon(Icons.access_time_filled,
                      color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "วันที่แจ้ง: ${repair['repair_date']?.substring(0, 10) ?? '-'}",
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // สถานะ
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(repair['status']),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  repair['status'] ?? 'ไม่มีข้อมูล',
                  style: GoogleFonts.prompt(
                    textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // พื้นหลัง
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  const SizedBox(height: 120),

                  // ส่วนหัว + ปุ่ม Back
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(
                                  userId: widget.userId,
                                  roomNumber: widget.roomNumber,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'แจ้งซ่อม',
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
                  ),

                  // ฟอร์มแจ้งซ่อม
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Colors.white.withOpacity(0.95),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(
                          color: Color(0xFFE8CFA8),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            _buildTitleBox('รายละเอียดปัญหา'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _detailsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8CFA8),
                                  ),
                                ),
                                hintText: 'กรอกรายละเอียดปัญหา...',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting ? null : _submitReport,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF8800),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: const BorderSide(
                                            color: Color(0xFFE8CFA8),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: _isSubmitting
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            )
                                          : Text(
                                              'ส่งเรื่อง',
                                              style: GoogleFonts.prompt(
                                                textStyle: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // รายการแจ้งซ่อม
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Colors.white.withOpacity(0.95),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(
                          color: Color(0xFFE8CFA8),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTitleBox('รายการแจ้งซ่อมของคุณ'),
                            const SizedBox(height: 10),
                            _buildRepairList(),
                          ],
                        ),
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
}
