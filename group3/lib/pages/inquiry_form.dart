  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';

  class InquiryFormScreen extends StatefulWidget {
    const InquiryFormScreen({super.key});

    @override
    State<InquiryFormScreen> createState() => _InquiryFormScreenState();
  }

  class _InquiryFormScreenState extends State<InquiryFormScreen> {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final _storage = const FlutterSecureStorage(); // ✅ JWT 토큰용

    bool _isSending = false;

    void _sendInquiry() async {
      if (!_formKey.currentState!.validate()) return;

      setState(() {
        _isSending = true;
      });

      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
final token = await _storage.read(key: 'jwt');

      if (token == null) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

final uri = Uri.parse('http://172.31.98.234:8080/api/setting/send-inquiry'); // 예시

      try {
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'title': title,
            'content': content,
          }),
        );

        setState(() {
          _isSending = false;
        });

        if (response.statusCode == 200) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('문의 완료'),
                content: const Text('문의가 성공적으로 전송되었습니다.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/index', (route) => false);
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('전송 실패: ${response.statusCode}')),
          );
          print('❌ 서버 오류 응답: ${response.body}');
        }
      } catch (e) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
        print('❌ 예외 발생: $e');
      }
    }

    @override
    void dispose() {
      _titleController.dispose();
      _contentController.dispose();
      super.dispose();
    }

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
          title: const Text('1:1 문의하기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: false,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '제목을 입력하세요.' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 15,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '내용을 입력하세요.' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('문의 보내기', style: TextStyle(fontSize: 16)),
                    onPressed: _isSending ? null : _sendInquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8e44ad),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    }
  }
