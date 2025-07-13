// lib/pages/setting/change_email.dart

import 'package:flutter/material.dart';

class ChangeEmailPage extends StatelessWidget {
  /// 실제로는 로그인된 유저 정보에서 가져오도록 바꿔주세요.
  final String currentEmail;

  const ChangeEmailPage({
    Key? key,
    this.currentEmail = 'user@example.com', // TODO: 실제 이메일로 대체
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        title: const Text('이메일 변경', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDDFE2)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2)),
                  BoxShadow(color: Colors.black12, blurRadius:16, offset: Offset(0,8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 제목
                  const Text(
                    '이메일 변경',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // 설명 텍스트
                  Text(
                    '현재 등록된 이메일은\n'
                    '$currentEmail\n'
                    '입니다.\n\n'
                    '이메일 변경을 위해 인증이 필요합니다.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // 인증하기 버튼
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 이메일 인증 페이지(또는 웹뷰)로 이동
                      Navigator.pushNamed(context, '/emailVerify');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('이메일 인증하기'),
                  ),

                  const SizedBox(height: 16),

                  // 뒤로가기
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
