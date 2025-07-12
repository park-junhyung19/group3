import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Inquiry {
  final String title;
  final String content;
  final String status;
  final DateTime createdAt;
  final String? adminReply;

  Inquiry({
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    this.adminReply,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? '미답변',
      createdAt: DateTime.parse(json['createdAt']),
      adminReply: json['reply'],
    );
  }
}

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Inquiry>> _inquiriesFuture;

  @override
  void initState() {
    super.initState();
    _inquiriesFuture = _fetchInquiries();
  }

  Future<List<Inquiry>> _fetchInquiries() async {
    const apiUrl = 'http://172.31.98.234:8080/api/setting/my-inquiries'; // ✅ 실제 API 주소
    final token = await _storage.read(key: 'jwt'); // ✅ jwt 키 사용

    if (token == null) {
      throw Exception('JWT 토큰이 없습니다.');
    }

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((e) => Inquiry.fromJson(e)).toList();
    } else {
      throw Exception('문의 불러오기 실패: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '나의 1:1 문의 목록',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: FutureBuilder<List<Inquiry>>(
        future: _inquiriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('문의 내역이 없습니다.'));
          }

          final inquiries = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            itemCount: inquiries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, idx) {
              final inquiry = inquiries[idx];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inquiry.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _StatusBadge(status: inquiry.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        inquiry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatDate(inquiry.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const Spacer(),
                          if (inquiry.adminReply != null)
                            Flexible(
                              child: Text(
                                '답변: ${inquiry.adminReply!}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == '답변완료';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFe8f5e9) : const Color(0xFFfbe9e7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? const Color(0xFF43a047) : const Color(0xFFff7043),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isDone ? const Color(0xFF388e3c) : const Color(0xFFd84315),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
