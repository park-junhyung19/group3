import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idController = TextEditingController();
  final pwController = TextEditingController();
  final storage = FlutterSecureStorage();

  bool isLoading = false;

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
    });
    print('로그인 버튼 클릭됨!');

    final url = Uri.parse('http://172.31.98.232:8080/api/auth/login');
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    final body = jsonEncode({
      "loginId": idController.text,
      "password": pwController.text,
    });

    print("로그인 요청 전송! body: $body");

    try {
      print("http.post 실행 직전!");
      final response = await http.post(url, headers: headers, body: body);

      print('서버 응답 코드: ${response.statusCode}');
      print('서버 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        if (token != null) {
          await storage.write(key: 'jwt', value: token);
          handleLoginSuccess(token); // ✅ 사용자 정보 디코딩
          print("JWT 토큰 저장됨: $token");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인 성공!")),
        );
        Navigator.pushReplacementNamed(context, '/index');
      } else if (response.statusCode == 401) {
        print("로그인 실패: 인증 오류");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("아이디 또는 비밀번호가 올바르지 않습니다.")),
        );
      } else if (response.statusCode == 403) {
        print("로그인 실패: 계정 정지");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("정지된 계정입니다.")),
        );
      } else {
        print("로그인 실패: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패 (${response.statusCode})")),
        );
      }
    } catch (e) {
      print("예외 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("서버 연결 실패")),
      );
    } finally {
      print("로그인 함수 종료, isLoading=false");
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleLoginSuccess(String token) async {
    await storage.write(key: 'jwt', value: token);
    final decoded = JwtDecoder.decode(token);
    final userId = decoded['sub'];
    print("✅ 현재 로그인된 사용자 ID: $userId");
  }

  Future<void> logoutUser() async {
    await storage.delete(key: 'jwt');
    print("JWT 토큰 삭제됨");
    Navigator.pushReplacementNamed(context, '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  '서담',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('로그인', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('비밀번호를 잊으셨나요?'),
                ),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('또는'),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Google 로그인'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('새 계정 만들기', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
