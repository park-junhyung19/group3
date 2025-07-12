// lib/pages/mypage.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';  // 같은 lib/pages/ 폴더 내이므로 상대경로로

const String baseUrl = 'http://172.31.98.235:8080';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();

  String _userId = '...';
  String _profileRawPath = ''; // 서버에서 넘어오는 "/uploads/xxx.jpg"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return;

    // JWT에서 sub 추출
    try {
      final decoded = JwtDecoder.decode(token);
      _userId = decoded['sub'] as String? ?? '...';
    } catch (_) {}

    // 프로필 API 호출
    final resp = await http.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      setState(() {
        _profileRawPath = data['profileImg'] as String? ?? '';
      });
    }
  }

  String _resolveImageUrl(String rawPath) {
    final filename = Uri.encodeComponent(rawPath.split('/').last);
    return '$baseUrl/api/posts/image?filename=$filename';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentRoute: '/mypage',
        userId: _userId,
        profileImg: _profileRawPath,
      ),
      appBar: AppBar(title: const Text('내 프로필')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 커버 + 프로필
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/heroic-20250622-224210-000.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileRawPath.isNotEmpty
                        ? NetworkImage(_resolveImageUrl(_profileRawPath))
                        : const AssetImage(
                            'assets/Screenshot_20250625_034855_KakaoStory1.jpg')
                            as ImageProvider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),
            // 닉네임 & 소개 & 버튼
            Column(
              children: [
                Text(
                  _userId,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '자기소개를 입력하세요',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('프로필 편집'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
            // 탭바
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: '게시물'),
                Tab(text: '답글'),
                Tab(text: '미디어'),
                Tab(text: '좋아요'),
              ],
            ),
            // 탭 뷰
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      ListTile(
                        leading: Icon(Icons.article),
                        title: Text('게시물이 없습니다.'),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      ListTile(
                        leading: Icon(Icons.reply),
                        title: Text('작성한 답글이 없습니다.'),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      ListTile(
                        leading: Icon(Icons.image),
                        title: Text('업로드한 미디어가 없습니다.'),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      ListTile(
                        leading: Icon(Icons.favorite),
                        title: Text('좋아요한 게시물이 없습니다.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
