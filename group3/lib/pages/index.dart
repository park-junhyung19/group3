// lib/pages/index_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';  // 같은 lib/pages/ 폴더 내이므로 상대경로로

const String baseUrl = 'http://192.168.0.53:8080';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _storage = const FlutterSecureStorage();
  String _userId = '...';
    String _nickname = '...'; // ✅ 이 줄 추가

  String _profileRawPath = ''; // 서버가 내려주는 rawPath, 예: "/uploads/abc.jpg"

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return;

    // 1) JWT에서 userId 추출
    try {
      final decoded = JwtDecoder.decode(token);
      _userId = decoded['sub'] as String? ?? '...';
    } catch (e) {
      debugPrint('❌ JWT 디코딩 실패: $e');
      return;
    }

    // 2) 백엔드에서 “내 프로필” rawPath 받아오기
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
  final rawNickname = data['nickname'] as String? ?? '';
  _nickname = rawNickname.isNotEmpty ? rawNickname : _userId;
});
      debugPrint('✅ 로그인 사용자: $_userId, rawPath: $_profileRawPath');
    } else {
      debugPrint('⚠️ 프로필 API 실패: ${resp.statusCode}');
      setState(() {
        _profileRawPath = '';
        _userId = _userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈 - $_userId'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      drawer: AppDrawer(
        currentRoute: '/index',
  nickname: _nickname,        // ✅ 닉네임 변수로 전달
        profileImg: _profileRawPath,  // rawPath 그대로 전달
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '게시물, 사용자, 해시태그 검색',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
        onPressed: () => Navigator.pushNamed(context, '/posts/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
