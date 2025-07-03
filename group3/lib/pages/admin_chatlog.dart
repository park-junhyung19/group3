import 'package:flutter/material.dart';

// 채팅 로그 데이터 모델
class ChatLog {
  final String timestamp;
  final String sender;
  final String message;
  final String status; // '정상' 또는 '신고됨'
  final String? reporter;

  ChatLog({
    required this.timestamp,
    required this.sender,
    required this.message,
    required this.status,
    this.reporter,
  });
}

class AdminChatlog extends StatefulWidget {
  @override
  State<AdminChatlog> createState() => _AdminChatlogState();
}

class _AdminChatlogState extends State<AdminChatlog> {
  List<ChatLog> allChats = [
    ChatLog(
      timestamp: '2025-07-03 13:10',
      sender: 'user01',
      message: '안녕하세요!',
      status: '정상',
      reporter: null,
    ),
    ChatLog(
      timestamp: '2025-07-03 13:15',
      sender: 'user02',
      message: '이 채팅은 신고됨',
      status: '신고됨',
      reporter: 'moderator',
    ),
    ChatLog(
      timestamp: '2025-07-02 17:45',
      sender: 'testuser',
      message: '광고 메시지입니다',
      status: '신고됨',
      reporter: 'user01',
    ),
    ChatLog(
      timestamp: '2025-06-30 09:12',
      sender: 'user03',
      message: '오늘 날씨 좋네요',
      status: '정상',
      reporter: null,
    ),
  ];

  String userFilter = '';
  String periodFilter = '';

  // 필터링 함수
  List<ChatLog> get filteredChats {
    final now = DateTime.now();
    return allChats.where((chat) {
      bool show = true;
      if (userFilter.isNotEmpty) {
        final t = userFilter.toLowerCase();
        if (!chat.sender.toLowerCase().contains(t) &&
            !(chat.message.toLowerCase().contains(t))) {
          show = false;
        }
      }
      if (periodFilter.isNotEmpty) {
        final chatDate = DateTime.tryParse(chat.timestamp.replaceAll(' ', 'T'));
        if (chatDate != null) {
          final diff = now.difference(chatDate).inDays;
          if (periodFilter == '1' && diff > 0) show = false;
          if (periodFilter == '3' && diff > 2) show = false;
          if (periodFilter == '7' && diff > 6) show = false;
        }
      }
      return show;
    }).toList();
  }

  // 상태별 색상
  Color statusColor(String status) {
    if (status == '신고됨') return Color(0xFFD32F2F);
    return Color(0xFF24A148);
  }

  Color? rowBg(String status) {
    if (status == '신고됨') return Color(0xFFFFF3F3);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return isMobile
        ? Scaffold(
            backgroundColor: Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: Color(0xFF232323),
              iconTheme: IconThemeData(color: Colors.white),
              title: Text('채팅 로그 관리', style: TextStyle(color: Colors.white)),
            ),
            drawer: SizedBox(
              width: 200,
              child: AdminSidebar(
                activeRoute: '/admin/chatlog',
                isDrawer: true,
              ),
            ),
            body: _buildMainContent(),
          )
        : Scaffold(
            backgroundColor: Color(0xFFF7F7F7),
            body: Row(
              children: [
                AdminSidebar(
                  activeRoute: '/admin/chatlog',
                  isDrawer: false,
                ),
                Expanded(child: _buildMainContent()),
              ],
            ),
          );
  }

  Widget _buildMainContent() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 1000),
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('채팅 로그 관리', style: TextStyle(fontSize: 22, color: Color(0xFF232323), fontWeight: FontWeight.bold)),
            SizedBox(height: 18),
            // 검색/필터 바
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '닉네임 또는 이메일 입력',
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => userFilter = v.trim()),
                    onSubmitted: (v) => setState(() => userFilter = v.trim()),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: periodFilter.isEmpty ? null : periodFilter,
                  hint: Text('전체 기간'),
                  borderRadius: BorderRadius.circular(8),
                  style: TextStyle(fontSize: 15, color: Colors.black),
                  items: [
                    DropdownMenuItem(value: '', child: Text('전체 기간')),
                    DropdownMenuItem(value: '1', child: Text('오늘')),
                    DropdownMenuItem(value: '3', child: Text('최근 3일')),
                    DropdownMenuItem(value: '7', child: Text('최근 7일')),
                  ],
                  onChanged: (v) => setState(() => periodFilter = v ?? ''),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF232323),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    textStyle: TextStyle(fontSize: 15),
                  ),
                  onPressed: () => setState(() {}),
                  child: Text('🔍 검색'),
                ),
              ],
            ),
            SizedBox(height: 18),
            // 테이블
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('시간')),
                    DataColumn(label: Text('송신자')),
                    DataColumn(label: Text('채팅 내용')),
                    DataColumn(label: Text('상태')),
                  ],
                  rows: filteredChats.isEmpty
                      ? [
                          DataRow(cells: [
                            DataCell(Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                '채팅 로그가 없습니다.',
                                style: TextStyle(color: Color(0xFF666666)),
                              ),
                            )),
                            ...List.generate(3, (_) => DataCell(Container())),
                          ])
                        ]
                      : filteredChats.map((chat) {
                          return DataRow(
                            color: MaterialStateProperty.all(rowBg(chat.status)),
                            cells: [
                              DataCell(Text(chat.timestamp)),
                              DataCell(Text(chat.sender)),
                              DataCell(Row(
                                children: [
                                  Expanded(
                                    child: Text(chat.message),
                                  ),
                                  if (chat.status == '신고됨' && chat.reporter != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        '🚨 신고자: ${chat.reporter!}',
                                        style: TextStyle(
                                          color: Color(0xFFD32F2F),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              )),
                              DataCell(Text(
                                chat.status,
                                style: TextStyle(
                                  color: statusColor(chat.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                            ],
                          );
                        }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------- 사이드바 (공통) ---------
class AdminSidebar extends StatelessWidget {
  final String activeRoute;
  final bool isDrawer;
  const AdminSidebar({required this.activeRoute, this.isDrawer = false});

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
      width: isDrawer ? null : 200,
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
          ...menuItems.map((item) => SidebarLink(
                icon: item['icon'] as String,
                label: item['label'] as String,
                route: item['route'] as String,
                active: activeRoute == item['route'],
                isDrawer: isDrawer,
              )),
          Divider(color: Colors.white24, thickness: 1, height: 8),
          SidebarLogoutLink(isDrawer: isDrawer),
        ],
      ),
    );
  }
}

class SidebarLink extends StatelessWidget {
  final String icon;
  final String label;
  final String route;
  final bool active;
  final bool isDrawer;
  SidebarLink({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Text(icon, style: TextStyle(fontSize: 18, color: active ? Color(0xFF4FC3F7) : Colors.white)),
      title: Text(label, style: TextStyle(color: active ? Color(0xFF4FC3F7) : Colors.white, fontSize: 15, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      selected: active,
      selectedTileColor: Color(0xFF30333A),
      onTap: () {
        if (!active) {
          if (isDrawer) Navigator.pop(context); // 모바일 Drawer는 닫기
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

class SidebarLogoutLink extends StatelessWidget {
  final bool isDrawer;
  const SidebarLogoutLink({this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Text('📕', style: TextStyle(fontSize: 18, color: Color(0xFFFF6666))),
      title: Text('로그아웃', style: TextStyle(color: Color(0xFFFF6666), fontSize: 15)),
      onTap: () {
        if (isDrawer) Navigator.pop(context); // Drawer 닫기만 (로그아웃 동작은 필요시 구현)
      },
    );
  }
}
