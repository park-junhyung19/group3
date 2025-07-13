import 'package:flutter/material.dart';
import 'confirm_password.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String language = '한국어';
  String profileVisibility = '전체 공개';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/index', (route) => false);
          },
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // ── 개인정보 변경 (중앙 다이얼로그) ──
          _buildListTile(
            icon: Icons.person,
            iconColor: Colors.blueGrey,
            title: '개인정보 변경',
            onTap: () {
              showDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (context) => Center(
                  child: SimpleDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: const Text(
                      '개인정보 변경',
                      textAlign: TextAlign.center,
                    ),
                    children: [
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/changePassword');
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.lock_outline),
                            SizedBox(width: 8),
                            Text('비밀번호 변경'),
                          ],
                        ),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/changeEmail');
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.email_outlined),
                            SizedBox(width: 8),
                            Text('이메일 주소 변경'),
                          ],
                        ),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/confirmPassword');                        },
                        child: Row(
                          children: const [
                            Icon(Icons.phone_outlined),
                            SizedBox(width: 8),
                            Text('전화번호 변경'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),

          

          

          // ── 다크모드 토글 ──
          SwitchListTile(
            secondary: const Icon(
              Icons.dark_mode,
              color: Colors.deepPurple,
              size: 24,
            ),
            title: const Text(
              '다크모드',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            value: isDarkMode,
            onChanged: (v) {
              setState(() => isDarkMode = v);
              // TODO: 실제 다크모드 적용 로직 (테마 변경 콜백 또는 SharedPreferences)
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            dense: true,
          ),

         

          // ── 1:1 문의 ──
          _buildListTile(
            icon: Icons.mail_outline,
            iconColor: Colors.orange,
            title: '1:1 문의',
            onTap: () {
              Navigator.pushNamed(context, '/inquiry_form');
            },
          ),

          // ── 내 문의 내역 ──
          _buildListTile(
            icon: Icons.description_outlined,
            iconColor: Color(0xFF8e44ad),
            title: '내 문의 내역',
            onTap: () {
              Navigator.pushNamed(context, '/inquiry_list');
            },
          ),

          const Divider(height: 32, thickness: 1),

          // ── 계정 탈퇴 ──
          _buildListTile(
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            title: '계정 탈퇴',
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('계정 탈퇴'),
                  content:
                      const Text('정말로 계정을 탈퇴하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: 계정 탈퇴 처리
                      },
                      child: const Text(
                        '탈퇴',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── 로그아웃 ──
          _buildListTile(
            icon: Icons.logout,
            iconColor: Colors.black54,
            title: '로그아웃',
            onTap: () {
              // TODO: 로그아웃 처리 (토큰 삭제 후 /login 이동)
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            )
          : null,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      horizontalTitleGap: 12,
      onTap: onTap,
    );
  }
}
