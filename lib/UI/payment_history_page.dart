import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PaymentHistoryPage extends StatefulWidget {
  final int userId;
  const PaymentHistoryPage({super.key, required this.userId});

  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> paymentHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:4000/api/payment_history/${widget.userId}"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          paymentHistory = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("ไม่พบข้อมูลประวัติการชำระเงินสำหรับผู้ใช้นี้");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching payment history: $error");
    }
  }

  String _formatMonth(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      const monthNames = [
        '',
        'มกราคม',
        'กุมภาพันธ์',
        'มีนาคม',
        'เมษายน',
        'พฤษภาคม',
        'มิถุนายน',
        'กรกฎาคม',
        'สิงหาคม',
        'กันยายน',
        'ตุลาคม',
        'พฤศจิกายน',
        'ธันวาคม'
      ];
      return "${monthNames[date.month]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // ✅ เปลี่ยนพื้นหลังให้ดูนุ่มนวล
      appBar: AppBar(
        title: Text(
          'ประวัติการชำระเงิน',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFFFF8800), // ✅ สีส้มสด
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF8800), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white, // ✅ สีพื้นหลังกล่องหัวข้อ
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'รายการชำระเงิน:',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: paymentHistory.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: Color(0xFFE8CFA8), // ✅ เส้นแบ่งระหว่างรายการ
                        thickness: 1.2,
                        height: 20,
                      ),
                      itemBuilder: (context, index) {
                        final payment = paymentHistory[index];
                        final String dateStr =
                            payment['payment_date'] ?? payment['created_at'] ?? "";
                        final String formattedMonth = _formatMonth(dateStr);

                        return Card(
                          color: Colors.white, // ✅ การ์ดเป็นสีขาว
                          elevation: 4, // ✅ เพิ่มเงาให้การ์ดดูมีมิติ
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFFE8CFA8), // ✅ ขอบสีเบจอ่อน
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'เดือน: $formattedMonth',
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'จำนวนเงิน: ${payment['amount_paid']} บาท',
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border:
                                            Border.all(color: Colors.green, width: 1),
                                      ),
                                      child: Text(
                                        'ชำระแล้ว',
                                        style: GoogleFonts.poppins(
                                          textStyle: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
