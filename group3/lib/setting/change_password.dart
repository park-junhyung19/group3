// lib/pages/setting/change_password.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const _baseHost = '172.31.98.234:8080';
  final _apiUrl = 'http://$_baseHost/api/setting/change-password';
  final _storage = const FlutterSecureStorage();

  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _currentError = '';
  String _newError     = '';
  String _confirmError = '';
  bool   _isLoading    = false;

  Future<void> _submit() async {
    setState(() {
      _currentError = '';
      _newError     = '';
      _confirmError = '';
    });

    final current = _currentCtrl.text.trim();
    final neu     = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    bool hasError = false;
    if (current.isEmpty) {
      _currentError = '현재 비밀번호를 입력해주세요.';
      hasError = true;
    }
    if (neu.length < 8) {
      _newError = '비밀번호는 최소 8자 이상이어야 합니다.';
      hasError = true;
    }
    if (neu != confirm) {
      _confirmError = '비밀번호가 일치하지 않습니다.';
      hasError = true;
    }
    if (hasError) {
      debugPrint('입력 검증 실패');
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('▶️ 비밀번호 변경 요청 시작');
      debugPrint('   URL: $_apiUrl');

      final token = await _storage.read(key: 'jwt');
      debugPrint('   JWT: ${token == null ? "없음" : "존재"}');

      final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'currentPassword': current,
            'newPassword':     neu,
            'confirmPassword': confirm,
          }),
        )
        .timeout(const Duration(seconds: 10));

      // UTF-8로 정확히 디코딩
      final raw = utf8.decode(response.bodyBytes);
      debugPrint('▶️ 응답: ${response.statusCode}, body: $raw');

      final data = raw.isNotEmpty
          ? jsonDecode(raw) as Map<String, dynamic>
          : {};

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '비밀번호가 변경되었습니다.')),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? '인증이 필요합니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? '오류: ${response.statusCode}')),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청 시간이 초과되었습니다.')),
      );
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 연결을 확인해주세요.')),
      );
    } catch (e, st) {
      debugPrint('예외: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.')),
      );
    } finally {
      debugPrint('▶️ 요청 종료');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDDFE2)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _currentCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '현재 비밀번호',
                      errorText: _currentError.isEmpty ? null : _currentError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '새 비밀번호',
                      errorText: _newError.isEmpty ? null : _newError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '새 비밀번호 확인',
                      errorText: _confirmError.isEmpty ? null : _confirmError,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('비밀번호 변경'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('← 설정으로 돌아가기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
