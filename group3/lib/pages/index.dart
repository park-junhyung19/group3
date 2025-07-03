import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final storage = const FlutterSecureStorage();
  String userId = '...'; // 초기 표시용
  final String profileImg = 'assets/Screenshot_20250625_034855_KakaoStory1.jpg';

  @override
  void initState() {
    super.initState();
    loadUserIdFromToken();
  }

  Future<void> loadUserIdFromToken() async {
    final token = await storage.read(key: 'jwt');
    if (token != null) {
      try {
        final decoded = JwtDecoder.decode(token);
        final id = decoded['sub'];
        setState(() {
          userId = id;
        });
        print("✅ IndexPage에서 로그인된 사용자: $userId");
      } catch (e) {
        print("❌ 토큰 디코딩 실패: $e");
      }
    } else {
      print("❌ JWT 토큰이 저장되어 있지 않음.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈 - $userId'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 24, bottom: 8),
                child: Text(
                  'Daily Log',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 32),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(profileImg),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      userId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              _drawerMenuItem(
                icon: Icons.home,
                label: '홈',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/index');
                },
              ),
              _drawerMenuItem(
                icon: Icons.article,
                label: '글 목록',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/posts');
                },
              ),
              _drawerMenuItem(
                icon: Icons.notifications,
                label: '알림',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/notifications');
                },
              ),
              _drawerMenuItem(
                icon: Icons.people,
                label: '친구 목록',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/friends');
                },
              ),
              _drawerMenuItem(
                icon: Icons.chat,
                label: '채팅',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/chat');
                },
              ),
              _drawerMenuItem(
                icon: Icons.live_tv,
                label: '숏폼',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/shorts');
                },
              ),
              _drawerMenuItem(
                icon: Icons.subscriptions,
                label: '구독 관리',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/subscriptions');
                },
              ),
              _drawerMenuItem(
                icon: Icons.person,
                label: '내 프로필',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/mypage');
                },
              ),
              _drawerMenuItem(
                icon: Icons.settings,
                label: '설정',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/setting');
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 16),
                child: Divider(height: 1, color: Colors.grey[300], thickness: 1),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 24),
                leading: const Icon(Icons.add),
                title: const Text('새 글 쓰기', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/posts/new');
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 24),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('로그아웃', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
                onTap: () async {
                  await storage.delete(key: 'jwt');
                  print("✅ 로그아웃: JWT 토큰 삭제됨");
                  Navigator.pushReplacementNamed(context, '/auth/login');
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 24),
                leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
                title: const Text('다크모드', style: TextStyle(fontSize: 16)),
                onTap: () {
                  // 다크모드 토글 처리 예정
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '게시물, 사용자, 해시태그 검색',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, idx) => ListTile(
                leading: const Icon(Icons.article),
                title: Text('게시물 제목 $idx'),
                subtitle: const Text('게시물 내용 예시...'),
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/posts/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _drawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24),
      leading: Icon(icon, color: Colors.black87),
      title: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      onTap: onTap,
      minLeadingWidth: 28,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}
