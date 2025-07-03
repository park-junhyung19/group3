import 'package:flutter/material.dart';

class Inquiry {
  final int userId;
  final String title;
  final String content;
  String status; // '미답변' 또는 '답변완료'
  final DateTime createdAt;
  String? reply;

  Inquiry({
    required this.userId,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    this.reply,
  });
}

class Admininquirypage extends StatefulWidget {
  @override
  State<Admininquirypage> createState() => _AdmininquirypageState();
}

class _AdmininquirypageState extends State<Admininquirypage> {
  List<Inquiry> inquiries = [
    Inquiry(
      userId: 1,
      title: '비밀번호 변경 문의',
      content: '비밀번호를 잊어버렸어요. 어떻게 해야 하나요?',
      status: '미답변',
      createdAt: DateTime(2025, 7, 1, 10, 25),
    ),
    Inquiry(
      userId: 2,
      title: '닉네임 변경',
      content: '닉네임을 바꾸고 싶어요.',
      status: '답변완료',
      createdAt: DateTime(2025, 6, 30, 17, 40),
      reply: '마이페이지 > 프로필 수정에서 변경 가능합니다.',
    ),
    Inquiry(
      userId: 3,
      title: '탈퇴 문의',
      content: '계정을 삭제하고 싶습니다.',
      status: '미답변',
      createdAt: DateTime(2025, 6, 29, 8, 12),
    ),
  ];

  final Map<int, TextEditingController> replyControllers = {};

  @override
  void dispose() {
    for (final c in replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color statusColor(String status) =>
      status == '답변완료' ? Color(0xFF2E8B57) : Color(0xFFFA383E);

  Color statusBg(String status) =>
      status == '답변완료' ? Color(0xFFE8F5E8) : Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return isMobile
        ? Scaffold(
            backgroundColor: Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: Color(0xFF232323),
              iconTheme: IconThemeData(color: Colors.white),
              title: Text('1:1 문의 관리', style: TextStyle(color: Colors.white)),
            ),
            drawer: SizedBox(
              width: 200,
              child: AdminSidebar(
                activeRoute: '/admin/inquiries',
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
                  activeRoute: '/admin/inquiries',
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
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        padding: EdgeInsets.all(24),
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
            Text('1:1 문의 관리', style: TextStyle(fontSize: 28, color: Color(0xFF232323), fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 1200),
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: MaterialStateProperty.all(Color(0xFFF0F2F5)),
                    columns: [
                      DataColumn(label: Text('사용자 ID')),
                      DataColumn(label: Text('제목')),
                      DataColumn(label: Text('내용')),
                      DataColumn(label: Text('상태')),
                      DataColumn(label: Text('작성일')),
                      DataColumn(label: Text('답변')),
                    ],
                    rows: inquiries.map((inquiry) {
                      replyControllers.putIfAbsent(
                          inquiry.userId, () => TextEditingController());
                      return DataRow(cells: [
                        DataCell(Text('${inquiry.userId}')),
                        DataCell(Text(inquiry.title)),
                        DataCell(
                          Tooltip(
                            message: inquiry.content,
                            child: Container(
                              width: 200,
                              child: Text(
                                inquiry.content,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg(inquiry.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inquiry.status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor(inquiry.status),
                              fontSize: 15,
                            ),
                          ),
                        )),
                        DataCell(Text(
                          '${inquiry.createdAt.year}-${inquiry.createdAt.month.toString().padLeft(2, '0')}-${inquiry.createdAt.day.toString().padLeft(2, '0')} ${inquiry.createdAt.hour.toString().padLeft(2, '0')}:${inquiry.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 13),
                        )),
                        DataCell(
                          inquiry.status == '답변완료'
                              ? Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8F8F8),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border(
                                      left: BorderSide(
                                        color: Color(0xFF4FC3F7),
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    inquiry.reply ?? '',
                                    style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                                  ),
                                )
                              : _buildReplyForm(inquiry),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyForm(Inquiry inquiry) {
    final controller = replyControllers[inquiry.userId]!;
    return Container(
      width: 220,
      child: Column(
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '답변 입력',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: EdgeInsets.all(8),
              isDense: true,
            ),
          ),
          SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF232323),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(vertical: 8),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                setState(() {
                  inquiry.reply = controller.text.trim();
                  inquiry.status = '답변완료';
                  controller.clear();
                });
                // 실제 서버 저장은 여기서 처리
              },
              child: Text('답변 저장'),
            ),
          ),
        ],
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
