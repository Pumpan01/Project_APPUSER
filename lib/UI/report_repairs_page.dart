import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportRepairsPage extends StatefulWidget {
  final int userId;
  final int roomNumber;

  const ReportRepairsPage(
      {super.key, required this.userId, required this.roomNumber});

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
    final url = Uri.parse('http://10.0.2.2:4000/api/repairs/${widget.userId}');
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

    setState(() {
      _isSubmitting = true;
    });

    final url = Uri.parse('http://10.0.2.2:4000/api/repairs');
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

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

  Future<void> _deleteReport(int repairId) async {
    final url = Uri.parse("http://10.0.2.2:4000/api/repairs/$repairId");
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  style: GoogleFonts.prompt(color: const Color(0xFFFF8800)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // พื้นหลังสีพีชอ่อน
      appBar: AppBar(
        title: Text(
          'แจ้งซ่อม',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF8800), // สีส้มสด
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleBox('รายละเอียดปัญหา'),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE8CFA8)),
                  ),
                  hintText: 'กรอกรายละเอียดปัญหา...',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              _buildSubmitButton(),
              const SizedBox(height: 30),
              _buildTitleBox('รายการแจ้งซ่อมของคุณ'),
              const SizedBox(height: 10),
              _buildRepairList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBox(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF8800), width: 2),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Text(
        title,
        style: GoogleFonts.prompt(
          textStyle: const TextStyle(fontSize: 18, color: Color(0xFFFF8800)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8800),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE8CFA8), width: 1.5),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'ส่งเรื่อง',
                style: GoogleFonts.prompt(
                  textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildRepairList() {
  return _repairList.isEmpty
      ? const Center(child: Text('ไม่มีรายการแจ้งซ่อม'))
      : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _repairList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final repair = _repairList[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          repair['description'] ?? 'ไม่มีข้อมูล',
                          style: GoogleFonts.prompt(
                            textStyle: const TextStyle(
                              fontSize: 18,
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
                  Row(
                    children: [
                      Icon(Icons.access_time_filled, color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "วันที่แจ้ง: ${repair['repair_date']?.substring(0, 10) ?? '-'}",
                        style: GoogleFonts.prompt(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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

/// แสดง Popup ยืนยันก่อนลบ
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
            child: Text("ยกเลิก", style: GoogleFonts.prompt(color: Colors.grey)),
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



}
