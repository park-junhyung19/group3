// lib/pages/setting/change_phone.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePhonePage extends StatefulWidget {
  const ChangePhonePage({Key? key}) : super(key: key);

  @override
  State<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  // 실제 IP 적용: 172.31.98.234
  static const _baseHost = '172.31.98.234:8080';
  final _apiUrl = 'http://$_baseHost/api/setting/change-phone';
  final _storage = const FlutterSecureStorage();

  final _phoneCtrl = TextEditingController();
  String _phoneError = '';
  bool _isLoading = false;

  bool _validatePhone(String phone) {
    final regex = RegExp(r'^\d{9,11}$');
    return regex.hasMatch(phone);
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    print('[DEBUG] submit pressed with phone: $phone');

    setState(() => _phoneError = '');

    if (phone.isEmpty) {
      setState(() => _phoneError = '전화번호를 입력해주세요.');
      print('[DEBUG] validation fail: empty phone');
      return;
    }
    if (!_validatePhone(phone)) {
      setState(() => _phoneError = '유효한 전화번호가 아닙니다.');
      print('[DEBUG] validation fail: invalid format');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // JWT 토큰 읽기
      final token = await _storage.read(key: 'jwt');
      print('[DEBUG] JWT: ${token == null ? "없음" : "존재"}');

      print('[DEBUG] calling change-phone API: $_apiUrl');

      final resp = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'newPhone': phone}),
      );

      print('[DEBUG] change-phone status: ${resp.statusCode}');
      print('[DEBUG] change-phone body: ${resp.body}');

      switch (resp.statusCode) {
        case 200:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('전화번호가 성공적으로 변경되었습니다.')),
          );
          // 설정 페이지로 이동
          Navigator.pushNamed(context, '/setting');
          break;
        case 400:
          final data400 = jsonDecode(resp.body);
          final err400 = data400['error'] ?? '잘못된 요청입니다.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err400)),
          );
          break;
        case 401:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증이 필요합니다. 다시 로그인해주세요.')),
          );
          break;
        case 403:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('권한이 없습니다.')),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 코드 ${resp.statusCode} 발생')),
          );
      }
    } catch (e) {
      print('[DEBUG] network error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('전화번호 변경'),
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
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: '새 전화번호',
                      hintText: '01012345678',
                      errorText: _phoneError.isEmpty ? null : _phoneError,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                        : const Text('전화번호 변경'),
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
