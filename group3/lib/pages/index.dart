import 'package:flutter/material.dart';

// IndexPage는 메인 홈 화면입니다.
// setting.dart 파일에 SettingsScreen이 정의되어 있다고 가정합니다.
class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('사용자명'),
              accountEmail: const Text('email@example.com'),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('홈'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/index');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('친구 목록'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/friends');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('채팅'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/chat'); // 채팅 페이지로 이동
              },
            ),
            ListTile(
              leading: const Icon(Icons.live_tv),
              title: const Text('숏폼'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('내 프로필'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/mypage');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('설정'),
              onTap: () {
                Navigator.pop(context); // 드로어 닫기
                Navigator.pushReplacementNamed(context, '/setting'); // 설정 페이지로 이동
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('새 글 쓰기'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 검색창
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
          // 게시물/검색 결과 리스트
          Expanded(
            child: ListView.builder(
              itemCount: 10, // 예시
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
          // 새 글 작성 페이지 이동
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
