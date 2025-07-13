// lib/pages/setting/confirm_password.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConfirmPasswordPage extends StatefulWidget {
  const ConfirmPasswordPage({Key? key}) : super(key: key);

  @override
  State<ConfirmPasswordPage> createState() => _ConfirmPasswordPageState();
}

class _ConfirmPasswordPageState extends State<ConfirmPasswordPage> {
  final _pwCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String _error = '';
  bool _isLoading = false;

  Future<void> _verify() async {
    final pw = _pwCtrl.text.trim();
    if (pw.isEmpty) {
      setState(() => _error = '비밀번호를 입력해주세요.');
      return;
    }
    setState(() {
      _error = '';
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt') ?? '';
      if (token.isEmpty) {
        setState(() => _error = '로그인 정보가 없습니다.');
        return;
      }

      final url = Uri.parse(
        'http://172.31.98.234:8080/api/setting/verify-password'
      );
      final bodyJson = jsonEncode({'password': pw});

      debugPrint('▶️ 요청 URL: $url');
      debugPrint('▶️ 요청 바디: $bodyJson');

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: bodyJson,
      );

      debugPrint('◀️ 응답 코드: ${resp.statusCode}');
      debugPrint('◀️ 응답 바디: ${resp.body}');

      if (resp.statusCode == 200) {
 Navigator.pushNamed(context, '/changePhone');
      } else if (resp.statusCode == 401) {
        final data = jsonDecode(resp.body);
        setState(() => _error = data['error'] ?? '비밀번호가 일치하지 않습니다.');
      } else {
        setState(() => _error = '서버 오류 (${resp.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ verify 예외: $e');
      setState(() => _error = '네트워크 오류가 발생했습니다:\n${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 확인')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                errorText: _error.isEmpty ? null : _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('확인'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('← 설정으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
