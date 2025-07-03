import 'package:flutter/material.dart';

void main() => runApp(AdminDashboardApp());

class AdminDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '관리자 대시보드',
      theme: ThemeData(fontFamily: 'NotoSansKR'),
      home: AdminDashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Color(0xFF232323),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('관리자 대시보드', style: TextStyle(color: Colors.white)),
        elevation: 1,
      ),
      drawer: Builder(
        builder: (context) {
          final width = MediaQuery.of(context).size.width;
          // 38% 비율, 최소 160, 최대 280
          final drawerWidth = width * 0.2 < 160
              ? 160.0
              : (width * 0.38 > 280 ? 280.0 : width * 0.38);
          return SizedBox(
            width: drawerWidth,
            child: AdminSidebar(isDrawer: true),
          );
        },
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DashboardCard(title: '총 회원 수', value: '1,234'),
              DashboardCard(title: '오늘 가입자 수', value: '56'),
              DashboardCard(title: '미처리 신고', value: '3'),
              DashboardCard(title: '1:1 문의', value: '2'),
            ],
          ),
          SizedBox(height: 24),
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F8FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text('📈 접속자 수 변화 그래프 (자리표시)', style: TextStyle(color: Colors.grey)),
                ),
                SizedBox(height: 16),
                ListBlock(
                  title: '최근 신고 내역',
                  items: [
                    '게시글 #34 / 사용자: 홍길동 / 사유: 욕설 / 처리: 대기',
                    '게시글 #28 / 사용자: test02 / 사유: 광고 / 처리: 대기',
                  ],
                ),
                SizedBox(height: 12),
                ListBlock(
                  title: '최근 1:1 문의',
                  items: [
                    '사용자: test01 / 제목: 비밀번호가 안 돼요 / 상태: 미답변',
                    '사용자: user99 / 제목: 닉네임 변경 문의 / 상태: 미답변',
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('🧭 빠른 이동', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF232323),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    child: Text('회원 관리'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF232323),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    child: Text('신고 관리'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF232323),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    child: Text('1:1 문의 관리'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminSidebar extends StatelessWidget {
  final bool isDrawer;
  AdminSidebar({this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'icon': '📊', 'label': '대시보드', 'route': '/admin/dashboard'},
      {'icon': '👥', 'label': '회원 관리', 'route': '/admin/members'},
      {'icon': '🚩', 'label': '신고 관리', 'route': '/admin/reports'},
      {'icon': '💬', 'label': '채팅 신고 관리', 'route': '/admin/chat-reports'},
      {'icon': '💬', 'label': '1:1 문의 관리', 'route': '/admin/inquiries'},
      {'icon': '💬', 'label': '채팅 로그 보기', 'route': '/admin/chatlog'},
    ];

    return Container(
      color: Color(0xFF232323),
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 12),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('관리자', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          Divider(color: Colors.white24, thickness: 1, height: 8),
          ...menuItems.map((item) => SidebarLink(item: item)),
          Divider(color: Colors.white24, thickness: 1, height: 8),
          SidebarLogoutLink(),
        ],
      ),
    );
  }
}

class SidebarLink extends StatelessWidget {
  final Map item;
  SidebarLink({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Text(item['icon'], style: TextStyle(fontSize: 18, color: Colors.white)),
      title: Text(item['label'], style: TextStyle(color: Colors.white, fontSize: 15)),
      onTap: () {
        // Navigator.pushNamed(context, item['route']);
        Navigator.pop(context); // Drawer 닫기
         Navigator.pushNamed(context, item['route']);

      },
    );
  }
}

class SidebarLogoutLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Text('📕', style: TextStyle(fontSize: 18, color: Color(0xFFFF6666))),
      title: Text('로그아웃', style: TextStyle(color: Color(0xFFFF6666), fontSize: 15)),
      onTap: () {
        // Navigator.pushNamed(context, '/admin/logout');
        Navigator.pop(context); // Drawer 닫기
      },
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  DashboardCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      child: Card(
        color: Color(0xFFF0F0F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF232323))),
            ],
          ),
        ),
      ),
    );
  }
}

class ListBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  ListBlock({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF232323), fontSize: 14)),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(top: 3),
                child: Text(item, style: TextStyle(color: Color(0xFF444444), fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
