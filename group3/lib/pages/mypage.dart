import 'package:flutter/material.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 첨부하신 이미지를 assets 폴더에 넣고 pubspec.yaml에 등록하세요.
    final String backgroundImg = 'assets/heroic-20250622-224210-000.jpg'; // 배경(커버) 이미지
    final String profileImg = 'assets/Screenshot_20250625_034855_KakaoStory1.jpg'; // 프로필 이미지

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 커버 이미지 + 프로필 이미지 (Stack)
            Stack(
              alignment: Alignment.center,
              children: [
                // 커버 이미지
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(backgroundImg),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // 프로필 이미지 (아래에 겹치게)
                Positioned(
                  bottom: -60,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(profileImg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70), // 프로필 이미지 높이만큼 여백
            // 닉네임, 소개, 편집 버튼
            Column(
              children: [
                const Text(
                  '구밍',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text(
                  '구밍입니다',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // 프로필 편집 페이지 이동
                      },
                      child: const Text('프로필 편집'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        // 더보기 메뉴 등
                      },
                      child: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
            // 탭바 (게시물/답글/미디어/좋아요)
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
            SizedBox(
              height: 400, // 원하는 높이로 조정
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 게시물 탭
                  ListView(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.article, color: Colors.black),
                        title: Text('게시물 제목', style: TextStyle(color: Colors.black)),
                        subtitle: Text('게시물이 없습니다.', style: TextStyle(color: Colors.black54)),
                      ),
                    ],
                  ),
                  // 답글 탭
                  ListView(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.reply, color: Colors.black),
                        title: Text('답글 내용', style: TextStyle(color: Colors.black)),
                        subtitle: Text('아직 작성한 답글이 없습니다.', style: TextStyle(color: Colors.black54)),
                      ),
                    ],
                  ),
                  // 미디어 탭
                  ListView(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.image, color: Colors.black),
                        title: Text('업로드한 미디어가 없습니다.', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                  // 좋아요 탭
                  ListView(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.favorite, color: Colors.black),
                        title: Text('좋아요한 게시물 제목', style: TextStyle(color: Colors.black)),
                        subtitle: Text('아직 좋아요한 게시물이 없습니다.', style: TextStyle(color: Colors.black54)),
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
