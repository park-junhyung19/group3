import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _storage = FlutterSecureStorage();

  String? errorMessage;
  bool _loading = false;

  Future<void> _login() async {
    setState(() {
      errorMessage = null;
      _loading = true;
    });

    final id = _idController.text.trim();
    final pw = _pwController.text;

    print('[로그인 시도] admin_id: $id');
    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.53:8080/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': id, 'admin_pw': pw}),
      );

      print('[로그인 응답] status: ${response.statusCode}');
      print('[로그인 응답] body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token != null) {
          await _storage.write(key: 'jwt_token', value: token);
          print('[로그인 성공] 토큰 저장 완료');
          // ✅ 저장된 토큰을 바로 읽어서 print
          final savedToken = await _storage.read(key: 'jwt_token');
          print('[SecureStorage에 저장된 JWT 토큰] $savedToken');
          setState(() => _loading = false);
          // 로그인 성공 → 관리자 대시보드로 이동
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        } else {
          print('[로그인 실패] 서버 응답에 토큰 없음');
          setState(() {
            errorMessage = '서버 응답에 토큰이 없습니다.';
            _loading = false;
          });
        }
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('[로그인 실패] error: ${data['error']}');
        setState(() {
          errorMessage = data['error'] ?? '로그인 실패 (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      print('[로그인 네트워크 예외] $e');
      setState(() {
        errorMessage = '네트워크 오류: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          width: 360,
          padding: EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('관리자 로그인',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              SizedBox(height: 30),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: '관리자 아이디',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  isDense: true,
                ),
                enabled: !_loading,
              ),
              SizedBox(height: 15),
              TextField(
                controller: _pwController,
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  isDense: true,
                ),
                obscureText: true,
                enabled: !_loading,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    textStyle: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text('로그인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
