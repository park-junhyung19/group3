import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
      backgroundColor: const Color(0xFFF8F3F8), // 연한 분홍 배경
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/index', (route) => false);
          },
        ),
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildListTile(
            icon: Icons.person,
            iconColor: Colors.blueGrey,
            title: '개인정보 변경',
            onTap: () {
              // TODO: 개인정보 변경 페이지 이동
            },
          ),
          _buildListTile(
            icon: Icons.shield_outlined,
            iconColor: Colors.teal,
            title: '프로필 공개 범위 설정',
            subtitle: profileVisibility,
            onTap: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('전체 공개'),
                      onTap: () => Navigator.pop(context, '전체 공개'),
                    ),
                    ListTile(
                      title: const Text('친구만 공개'),
                      onTap: () => Navigator.pop(context, '친구만 공개'),
                    ),
                    ListTile(
                      title: const Text('비공개'),
                      onTap: () => Navigator.pop(context, '비공개'),
                    ),
                  ],
                ),
              );
              if (result != null) {
                setState(() {
                  profileVisibility = result;
                });
              }
            },
          ),
          _buildListTile(
            icon: Icons.block,
            iconColor: Colors.redAccent,
            title: '차단 사용자 관리',
            onTap: () {
              // TODO: 차단 사용자 관리 페이지 이동
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Colors.deepPurple, size: 24),
            title: const Text(
              '다크모드',
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black),
            ),
            value: isDarkMode,
            onChanged: (v) {
              setState(() {
                isDarkMode = v;
                // TODO: 실제 다크모드 적용 로직
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            dense: true,
          ),
          _buildListTile(
            icon: Icons.language,
            iconColor: Colors.green,
            title: '언어 설정',
            subtitle: language,
            onTap: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('한국어'),
                      onTap: () => Navigator.pop(context, '한국어'),
                    ),
                    ListTile(
                      title: const Text('English'),
                      onTap: () => Navigator.pop(context, 'English'),
                    ),
                  ],
                ),
              );
              if (result != null) {
                setState(() {
                  language = result;
                });
              }
            },
          ),
          _buildListTile(
            icon: Icons.mail_outline,
            iconColor: Colors.orange,
            title: '1:1 문의',
            onTap: () {
              Navigator.pushNamed(context, '/inquiry_form');
            },
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF8e44ad),
            title: '내 문의 내역',
            onTap: () {
    Navigator.pushNamed(context, '/inquiry_list');
            },
          ),
          const Divider(height: 32, thickness: 1),
          _buildListTile(
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            title: '계정 탈퇴',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('계정 탈퇴'),
                  content: const Text('정말로 계정을 탈퇴하시겠습니까?'),
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
                      child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.logout,
            iconColor: Colors.black54,
            title: '로그아웃',
            onTap: () {
              // TODO: 로그아웃 처리
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
        style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54))
          : null,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      minLeadingWidth: 0,
      horizontalTitleGap: 12,
      onTap: onTap,
    );
  }
}
