import 'package:flutter/material.dart';

class Inquiry {
  final String title;
  final String content;
  final String status; // '미답변' or '답변완료'
  final DateTime createdAt;
  final String? adminReply;

  Inquiry({
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    this.adminReply,
  });
}

class InquiryListScreen extends StatelessWidget {
  const InquiryListScreen({super.key});

  // 예시 더미 데이터
  List<Inquiry> get inquiries => [
        Inquiry(
          title: '로그인 오류가 발생해요',
          content: '앱에서 로그인이 되지 않고 계속 에러가 납니다. 어떻게 해야 하나요?',
          status: '미답변',
          createdAt: DateTime(2025, 6, 20, 14, 30),
        ),
        Inquiry(
          title: '프로필 사진 변경 문의',
          content: '프로필 사진을 바꾸고 싶은데, 어떤 형식의 이미지만 가능한가요?',
          status: '답변완료',
          createdAt: DateTime(2025, 6, 18, 10, 5),
          adminReply: 'jpg, png, gif 이미지를 지원합니다.',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/index', (route) => false);
          },
        ),
        title: const Text('나의 1:1 문의 목록',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: inquiries.isEmpty
          ? const Center(
              child: Text(
                '문의 내역이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              itemCount: inquiries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final inquiry = inquiries[idx];
                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목과 상태 뱃지
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                inquiry.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _StatusBadge(status: inquiry.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 내용 요약
                        Text(
                          inquiry.content,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // 하단: 날짜, 답변
                        Row(
                          children: [
                            Text(
                              _formatDate(inquiry.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                            const Spacer(),
                            if (inquiry.adminReply != null)
                              Icon(Icons.mark_email_read, color: Colors.green, size: 18),
                            if (inquiry.adminReply != null)
                              const SizedBox(width: 4),
                            if (inquiry.adminReply != null)
                              Flexible(
                                child: Text(
                                  inquiry.adminReply!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
