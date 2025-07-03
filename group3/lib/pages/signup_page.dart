import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // 입력값 컨트롤러
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  final pwConfirmController = TextEditingController();
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final phoneController = TextEditingController();

  bool agree1 = false;
  bool agree2 = false;
  bool agree3 = false;

  bool isLoading = false;

  Future<void> signupUser() async {
    print('가입하기 버튼 클릭됨!');

    // 입력값 검증
    if (idController.text.isEmpty ||
        emailController.text.isEmpty ||
        pwController.text.isEmpty ||
        pwConfirmController.text.isEmpty ||
        nameController.text.isEmpty ||
        nicknameController.text.isEmpty) {
      print('입력값 누락!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 필수 항목을 입력하세요.")),
      );
      return;
    }
    if (pwController.text != pwConfirmController.text) {
      print('비밀번호 불일치!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
      );
      return;
    }
    if (!agree1 || !agree2) {
      print('필수 약관 미동의!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("필수 약관에 동의해야 합니다.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://172.31.98.241:8080/api/auth/signup');
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final body = jsonEncode({
      "loginId": idController.text,
      "userName": nameController.text,
      "password": pwController.text,
      "passwordConfirm": pwConfirmController.text,
      "email": emailController.text,
      "nickname": nicknameController.text,
      "phone": phoneController.text,
    });

    print("회원가입 요청 전송! body: $body");

    try {
      print("http.post 실행 직전!");
      final response = await http.post(url, headers: headers, body: body);

      print('서버 응답 코드: ${response.statusCode}');
      print('서버 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        print("회원가입 성공!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입 성공!")),
        );
        Navigator.pushReplacementNamed(context, '/auth/login');
      } else {
        print("회원가입 실패: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원가입 실패: ${response.body}")),
        );
      }
    } catch (e) {
      print("예외 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("서버 연결 실패")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '빠르고 쉽게 가입할 수 있습니다.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 18),
                _buildTextField('ID', '아이디를 입력하세요', controller: idController),
                const SizedBox(height: 16),
                _buildTextField('이메일', '이메일 주소를 입력하세요', controller: emailController),
                const SizedBox(height: 16),
                _buildTextField('비밀번호', '비밀번호를 입력하세요', obscure: true, controller: pwController),
                const SizedBox(height: 16),
                _buildTextField('비밀번호 확인', '비밀번호를 다시 입력하세요', obscure: true, controller: pwConfirmController),
                const SizedBox(height: 16),
                _buildTextField('이름', '이름을 입력하세요', controller: nameController),
                const SizedBox(height: 16),
                _buildTextField('닉네임', '닉네임을 입력하세요', controller: nicknameController),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('휴대폰 번호 (선택)', '예: 010-1234-5678', controller: phoneController),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        // 인증번호 발송 로직 필요시 구현
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        minimumSize: const Size(110, 48),
                      ),
                      child: const Text('인증번호 받기'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                CheckboxListTile(
                  value: agree1,
                  onChanged: (v) => setState(() => agree1 = v ?? false),
                  title: const Text('(필수) 이용약관 동의'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: agree2,
                  onChanged: (v) => setState(() => agree2 = v ?? false),
                  title: const Text('(필수) 개인정보 수집 및 이용 동의'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: agree3,
                  onChanged: (v) => setState(() => agree3 = v ?? false),
                  title: const Text('(선택) 마케팅 정보 수신 동의'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: isLoading ? null : signupUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('가입하기', style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/login');
                  },
                  child: const Text("로그인 화면으로 이동 테스트"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/auth/login');
                  },
                  child: const Text('이미 계정이 있으신가요?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool obscure = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }
}
