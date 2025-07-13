import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'http://192.168.0.53:8080';

String _resolveUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  final filename = Uri.encodeComponent(path.split('/').last);
  return '$baseUrl/api/posts/image?filename=$filename';
}

/// 메뉴 아이템 모델
class MenuItemModel {
  final IconData icon;
  final String label;
  final String route;

  const MenuItemModel({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// 공통 사이드바 위젯
class AppDrawer extends StatelessWidget {
  final String currentRoute;
final String nickname;          // ✅ 바뀐 이름
  final String profileImg; // rawPath (e.g. "/uploads/xxx.jpg") or 애셋 경로
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  const AppDrawer({
    required this.currentRoute,
  required this.nickname,       // ✅ 바뀐 이름
    required this.profileImg,
    Key? key,
  }) : super(key: key);

  // 메인 메뉴 리스트
  List<MenuItemModel> get _mainMenu => const [
        MenuItemModel(icon: Icons.home, label: '홈', route: '/index'),
        MenuItemModel(icon: Icons.article, label: '글 목록', route: '/posts'),
        MenuItemModel(icon: Icons.notifications, label: '알림', route: '/notifications'),
        MenuItemModel(icon: Icons.live_tv, label: '숏폼', route: '/shorts'),
        MenuItemModel(icon: Icons.chat, label: '채팅', route: '/chat'),
        MenuItemModel(icon: Icons.person, label: '내 프로필', route: '/mypage'),
        MenuItemModel(icon: Icons.settings, label: '설정', route: '/setting'),
      ];

  // 서브 메뉴 리스트
  List<MenuItemModel> get _profileMenu => const [
        MenuItemModel(icon: Icons.home, label: '홈', route: '/index'),
        MenuItemModel(icon: Icons.people, label: '친구 목록', route: '/friends'),
        MenuItemModel(icon: Icons.subscriptions, label: '구독 관리', route: '/subscriptions'),
        MenuItemModel(icon: Icons.person, label: '내 프로필', route: '/mypage'),
      ];

  @override
  Widget build(BuildContext context) {
    final isProfile = currentRoute == '/mypage';
    final items = isProfile ? _profileMenu : _mainMenu;

    // rawPath → full URL
    final imageUrl = _resolveUrl(profileImg);

    return Drawer(
      child: Column(
        children: [
          // 유저 정보 헤더
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.transparent),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.only(left: 24, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : const AssetImage('assets/Screenshot_20250625_034855_KakaoStory1.jpg') as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 12),
                Text(
                  nickname,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 메뉴 리스트
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 메뉴 항목
                ...items.map((item) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 24),
                    leading: Icon(item.icon, color: Colors.black87),
                    title: Text(item.label,
                        style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -2),
                    minLeadingWidth: 28,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    selectedTileColor: Colors.transparent,
                    onTap: () {
                      Navigator.pop(context);
                      if (item.route != currentRoute) {
                        Navigator.pushReplacementNamed(context, item.route);
                      }
                    },
                  );
                }).toList(),

                // 구분선
                const Padding(
                  padding: EdgeInsets.only(left: 24, right: 16),
                  child: Divider(height: 1, color: Colors.grey),
                ),

                // 하단 공통 메뉴
                ...[
                  {'icon': Icons.add, 'label': '새 글 쓰기', 'route': '/posts/new', 'color': Colors.black87},
                  {'icon': Icons.logout, 'label': '로그아웃', 'route': '/auth/login', 'color': Colors.redAccent},
                  {'icon': Icons.nightlight_round, 'label': '다크 모드', 'route': null, 'color': Colors.indigo},
                ].map((menu) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 24),
                    leading: Icon(menu['icon'] as IconData, color: menu['color'] as Color),
                    title: Text(menu['label'] as String,
                        style: TextStyle(fontSize: 16, color: menu['color'] as Color)),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -2),
                    minLeadingWidth: 28,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    selectedTileColor: Colors.transparent,
                    onTap: () async {
                      Navigator.pop(context);
                      if (menu['label'] == '로그아웃') await storage.delete(key: 'jwt');
                      if (menu['route'] != null) {
                        Navigator.pushReplacementNamed(context, menu['route'] as String);
                      }
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
