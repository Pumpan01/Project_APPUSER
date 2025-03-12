import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class WaterBillPage extends StatefulWidget {
  final int userId;

  const WaterBillPage({super.key, required this.userId});

  @override
  State<WaterBillPage> createState() => _WaterBillPageState();
}

class _WaterBillPageState extends State<WaterBillPage> {
  XFile? _slipImage;
  bool _showSlipLink = false;
  bool _isLoading = true;
  List<dynamic>? _billsData;
  Map<String, dynamic>? _userData;
  dynamic _selectedBill;
  bool _previewOpen = false;
  String _previewImage = "";
  bool _isSendingSlip = false;

  /// ดึงข้อมูลผู้ใช้และบิลของห้อง
  Future<void> _fetchBillData() async {
    try {
      // ดึงข้อมูลผู้ใช้จาก API ด้วย userId
      final responseUser = await http.get(
        Uri.parse("https://api.horplus.work/api/users/${widget.userId}"),
      );
      if (responseUser.statusCode != 200) {
        setState(() {
          _isLoading = false;
        });
        print("❌ Error: ${responseUser.statusCode}");
        return;
      }
      final userData = json.decode(responseUser.body);
      setState(() {
        _userData = userData;
      });

      // ใช้ room_number ของผู้ใช้ในการดึงข้อมูลบิลของห้องนั้น
      final response = await http.get(
        Uri.parse("https://api.horplus.work/api/bills/room/${userData['room_number']}"),
      );
      if (response.statusCode == 200) {
        List<dynamic> bills = json.decode(response.body);
        setState(() {
          _billsData = bills;
          _isLoading = false;
        });
      } else {
        setState(() {
          _billsData = [];
          _isLoading = false;
        });
        print("❌ Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error fetching bill: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBillData();
  }

  Future<void> _showCustomDialog(BuildContext context, String title,
      String message, IconData icon, Color color) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(StateSetter setStateDialog) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setStateDialog(() {
        _slipImage = image;
        _showSlipLink = true;
      });
    }
  }

  bool validateSlip(Map<String, dynamic> slipData, double requiredAmount) {
    String receiverName = slipData['data']['receiver']['displayName'];
    if (receiverName != "นาย วิชญพัฒน์ เ") {
      print("❌ ชื่อผู้รับเงินไม่ตรงกัน");
      return false;
    }

    double amount = slipData['data']['amount'].toDouble();
    if ((amount - requiredAmount).abs() > 0.01) {
      print("❌ ยอดเงินไม่ตรงกัน: $amount ($requiredAmount)");
      return false;
    }

    DateTime transTime = DateTime.parse(slipData['data']['transTimestamp']);
    DateTime currentTime = DateTime.now().toUtc();
    Duration difference = currentTime.difference(transTime);

    // ถ้าเวลาการโอนเกิน 30 นาที
    if (difference.inMinutes > 100000) {
      print("❌ เวลาการโอนเกิน 30 นาที");
      return false;
    }

    print("✅ สลิปผ่านการตรวจสอบครบทั้ง 3 เงื่อนไข");
    return true;
  }

  Future<void> _sendSlipToAdmin(int billId, double amount) async {
    if (_slipImage == null) return;

    try {
      // แสดง Popup โหลด
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text("กำลังส่งสลิป...", style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      );

      var slipOkRequest = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.slipok.com/api/line/apikey/39124"),
      );

      slipOkRequest.headers.addAll({
        "x-authorization": "SLIPOKW5UNGCQ",
      });

      slipOkRequest.files.add(
        await http.MultipartFile.fromPath('files', _slipImage!.path),
      );

      var slipOkResponse = await slipOkRequest.send();
      var slipOkResponseBody =
          await http.Response.fromStream(slipOkResponse);

      // ปิด Popup โหลด
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (slipOkResponse.statusCode == 200) {
        Map<String, dynamic> slipData =
            json.decode(slipOkResponseBody.body);

        if (!validateSlip(slipData, amount)) {
          String errorMessage = "สลิปไม่ผ่านการตรวจสอบ";
          String receiverName = slipData['data']['receiver']['displayName'];
          double slipAmount = slipData['data']['amount'].toDouble();
          DateTime transTime =
              DateTime.parse(slipData['data']['transTimestamp']);
          DateTime currentTime = DateTime.now().toUtc();
          Duration difference = currentTime.difference(transTime);

          if (receiverName != "นาย วิชญพัฒน์ เ") {
            errorMessage =
                "ชื่อผู้รับเงินไม่ตรงกัน กรุณาตรวจสอบสลิป";
          } else if ((slipAmount - amount).abs() > 0.01) {
            errorMessage =
                "ยอดเงินที่โอนไม่ตรงกับบิล กรุณาตรวจสอบสลิป";
          } else if (difference.inMinutes > 30) {
            errorMessage =
                "สลิปหมดอายุ กรุณาใช้สลิปที่โอนล่าสุด";
          }

          Future.delayed(Duration.zero, () {
            if (mounted) {
              _showStatusDialog(
                context,
                "สลิปไม่ถูกต้อง",
                errorMessage,
                Icons.warning,
                const Color(0xFFFF8800),
              );
            }
          });
          return;
        }

        print("✅ สลิปถูกต้อง (ตรวจสอบผ่านแล้ว)");

        var uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse("https://api.horplus.work/api/upload"),
        );

        uploadRequest.files.add(
          await http.MultipartFile.fromPath('image', _slipImage!.path),
        );

        var uploadResponse = await uploadRequest.send();
        var uploadResponseBody =
            await http.Response.fromStream(uploadResponse);

        if (uploadResponse.statusCode == 200) {
          final uploadData = json.decode(uploadResponseBody.body);
          String slipPath = uploadData['file']['path'];
          String paidDate =
              DateTime.now().toIso8601String().split("T")[0];

          var updateResponse = await http.put(
            Uri.parse("https://api.horplus.work/api/bills/$billId"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "slip_path": slipPath,
              "payment_state": "paid",
              "paid_date": paidDate,
              "user_id": widget.userId,
            }),
          );

          if (updateResponse.statusCode == 200) {
            print("✅ ชำระเงินและบันทึกข้อมูลบิลสำเร็จ");

            Future.delayed(Duration.zero, () {
              if (mounted) {
                _showStatusDialog(
                  context,
                  "ชำระเงินสำเร็จ",
                  "สลิปถูกต้องและบันทึกเรียบร้อย",
                  Icons.check_circle,
                  Colors.green,
                );
              }
            });

            _fetchBillData(); // โหลดข้อมูลบิลใหม่
          } else {
            print("❌ ไม่สามารถอัปเดตสถานะบิลได้");

            Future.delayed(Duration.zero, () {
              if (mounted) {
                _showStatusDialog(
                  context,
                  "เกิดข้อผิดพลาด",
                  "ไม่สามารถอัปเดตสถานะบิลได้",
                  Icons.error,
                  Colors.red,
                );
              }
            });
          }
        } else {
          print("❌ การอัปโหลดสลิปไม่สำเร็จ");

          Future.delayed(Duration.zero, () {
            if (mounted) {
              _showStatusDialog(
                context,
                "เกิดข้อผิดพลาด",
                "อัปโหลดสลิปไม่สำเร็จ กรุณาลองใหม่",
                Icons.error,
                Colors.red,
              );
            }
          });
        }
      } else {
        print("❌ สลิปไม่ถูกต้อง (SlipOK ปฏิเสธ)");

        Future.delayed(Duration.zero, () {
          if (mounted) {
            _showStatusDialog(
              context,
              "สลิปไม่ถูกต้อง",
              "กรุณาใช้สลิปที่ถูกต้อง",
              Icons.warning,
              const Color(0xFFFF8800),
            );
          }
        });
      }
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดในการส่งสลิป: $e");

      Future.delayed(Duration.zero, () {
        if (mounted) {
          _showStatusDialog(
            context,
            "เกิดข้อผิดพลาด",
            "ข้อผิดพลาดในการส่งข้อมูล: $e",
            Icons.error,
            Colors.red,
          );
        }
      });
    }
  }

  Future<void> _showStatusDialog(BuildContext context, String title,
      String message, IconData icon, Color color) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // ป้องกันการปิด popup โดยไม่ได้ตั้งใจ
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('ตกลง', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  /// แสดง popup รายละเอียดบิล (สำหรับบิลที่ถูกเลือก)
  void _showPaymentPopup(dynamic bill, int index) {
    setState(() {
      _selectedBill = bill;
      _showSlipLink = false;
      _slipImage = null;
      _isSendingSlip = false;
    });

    double totalCharge = bill['total_amount'] is String
        ? double.tryParse(bill['total_amount']) ?? 0
        : bill['total_amount'] ?? 0;

    var meter = bill['meter'];
    String imageUrl = 'https://api.horplus.work/$meter';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFFFF8800), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ชำระบิลที่ $index',
                  style: GoogleFonts.prompt(
                    textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8800)),
                  ),
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Image.network(
                    'https://promptpay.io/0963042365/$totalCharge',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('ไม่พบ QR Code');
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showImagePreview(imageUrl),
                    icon: const Icon(Icons.visibility,
                        color: Colors.black),
                    label: const Text('รูปมิเตอร์',
                        style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(setStateDialog),
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('แนบสลิปการโอน',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8800),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (_slipImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          Text(
                            'ไฟล์สลิปที่แนบ: ${_slipImage!.name}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.green),
                          ),
                          const SizedBox(height: 10),
                          Image.file(
                            File(_slipImage!.path),
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSendingSlip
                        ? null
                        : () async {
                            setStateDialog(() {
                              _isSendingSlip = true;
                            });
                            await _sendSlipToAdmin(bill['bill_id'], totalCharge);
                            setStateDialog(() {
                              _isSendingSlip = false;
                            });
                            Navigator.of(context).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSendingSlip
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ส่งสลิป',
                            style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ปิด',
                    style: TextStyle(color: Color(0xFFFF8800))),
              ),
            ],
          );
        });
      },
    );
  }

  /// แสดง popup รูปภาพแบบเต็ม (preview)
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(8),
          content: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text("ไม่สามารถแสดงรูปได้"));
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ปิด",
                  style: TextStyle(color: Color(0xFFFF8800))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // พื้นหลังโปร่งใส
      backgroundColor: Colors.transparent,
      // ใช้ Stack เพื่อวางพื้นหลังเต็มจอ
      body: Stack(
        children: [
          // พื้นหลังสีส้ม + รูปภาพ
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8800),
              image: DecorationImage(
                image: AssetImage("images/backgroundmain.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // เนื้อหาหลัก
          SafeArea(
            child: Column(
              children: [
                // เพิ่ม SizedBox เพื่อเลื่อนคอนเทนต์ลงมา
                const SizedBox(height: 120),

                // ส่วนหัว + ปุ่ม Back
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // ปุ่มย้อนกลับ (สีดำ)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          // กลับไปหน้า HomePage
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(
                                userId: widget.userId,
                                roomNumber: 0,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // ข้อความ "แจ้งซ่อม" ใช้ GoogleFonts.prompt
                      Text(
                        'บิลค่าน้ำค่าไฟ',
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

                // เช็ค loading / data
                _isLoading
                    ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _billsData == null || _billsData!.isEmpty
                        ? const Expanded(
                            child: Center(child: Text("ไม่พบบิลของคุณ")),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _billsData!.length,
                                      itemBuilder: (context, index) {
                                        final bill = _billsData![index];
                                        double billTotal =
                                            bill['total_amount'] is String
                                                ? double.tryParse(bill['total_amount']) ?? 0
                                                : bill['total_amount'] ?? 0;
                                        double billWater =
                                            bill['water_units'] is String
                                                ? double.tryParse(bill['water_units']) ?? 0
                                                : bill['water_units'] ?? 0;
                                        double billElectricity =
                                            bill['electricity_units'] is String
                                                ? double.tryParse(
                                                      bill['electricity_units'],
                                                    ) ??
                                                    0
                                                : bill['electricity_units'] ?? 0;

                                        return Card(
                                          color: Colors.white,
                                          elevation: 4,
                                          margin:
                                              const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                        horizontal: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              const Color(0xFFFF8800),
                                                          width: 2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        'บิลที่ ${index + 1}',
                                                        style: GoogleFonts.prompt(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color:
                                                              const Color(0xFFFF8800),
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => _showPaymentPopup(
                                                        bill,
                                                        index + 1,
                                                      ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(8),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 10,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'ชำระเงิน',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Divider(color: Colors.grey.shade300),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'ค่าน้ำ: $billWater หน่วย',
                                                  style:
                                                      const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ค่าไฟ: $billElectricity หน่วย',
                                                  style:
                                                      const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ยอดรวม: $billTotal บาท',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
