import 'package:flutter/material.dart';

// 채팅 신고 데이터 모델
class ChatReport {
  final int id;
  final String reporter;
  final int messageId;
  final String reason;
  final DateTime createdAt;
  String status; // "PENDING", "RESOLVED", "REJECTED"

  ChatReport({
    required this.id,
    required this.reporter,
    required this.messageId,
    required this.reason,
    required this.createdAt,
    required this.status,
  });
}

class AdminChatreportPage extends StatefulWidget {
  @override
  State<AdminChatreportPage> createState() => _AdminChatreportPageState();
}

class _AdminChatreportPageState extends State<AdminChatreportPage> {
  List<ChatReport> reports = [
    ChatReport(
      id: 1,
      reporter: 'user123',
      messageId: 45,
      reason: 'spam',
      createdAt: DateTime(2025, 7, 1, 12, 30),
      status: 'PENDING',
    ),
    ChatReport(
      id: 2,
      reporter: 'alice',
      messageId: 99,
      reason: 'harassment',
      createdAt: DateTime(2025, 6, 30, 18, 12),
      status: 'RESOLVED',
    ),
    ChatReport(
      id: 3,
      reporter: 'bob',
      messageId: 77,
      reason: 'other',
      createdAt: DateTime(2025, 6, 29, 9, 50),
      status: 'REJECTED',
    ),
  ];

  String reasonLabel(String code) {
    switch (code) {
      case 'spam':
        return '스팸 또는 광고';
      case 'harassment':
        return '괴롭힘 또는 혐오 발언';
      case 'inappropriate':
        return '부적절한 콘텐츠';
      case 'other':
        return '기타';
      default:
        return code;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Color(0xFFFF6B35);
      case 'RESOLVED':
        return Color(0xFF28A745);
      case 'REJECTED':
        return Color(0xFFDC3545);
      default:
        return Colors.grey;
    }
  }

  String statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return '처리 대기';
      case 'RESOLVED':
        return '완료';
      case 'REJECTED':
        return '거부';
      default:
        return status;
    }
  }

  Color processedBg(String status) {
    switch (status) {
      case 'RESOLVED':
        return Color(0xFFD4EDDA);
      case 'REJECTED':
        return Color(0xFFF8D7DA);
      default:
        return Colors.transparent;
    }
  }

  Color processedFg(String status) {
    switch (status) {
      case 'RESOLVED':
        return Color(0xFF155724);
      case 'REJECTED':
        return Color(0xFF721C24);
      default:
        return Colors.black;
    }
  }

  void processStatus(int id, String newStatus) async {
    bool ok = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('신고 처리'),
        content: Text('신고를 ${newStatus == 'RESOLVED' ? '완료' : '거부'} 처리하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('확인')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        final idx = reports.indexWhere((r) => r.id == id);
        if (idx != -1) reports[idx].status = newStatus;
      });
      // 실제 서버 연동은 여기서 처리
    }
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
              title: Text('채팅 신고 관리', style: TextStyle(color: Colors.white)),
            ),
            drawer: SizedBox(
              width: 200,
              child: AdminSidebar(
                activeRoute: '/admin/chat-reports',
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
                  activeRoute: '/admin/chat-reports',
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
        constraints: BoxConstraints(maxWidth: 1200),
        margin: EdgeInsets.symmetric(vertical: 40),
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
            Text('채팅 신고 관리', style: TextStyle(fontSize: 28, color: Color(0xFF232323), fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('신고자')),
                    DataColumn(label: Text('메시지 ID')),
                    DataColumn(label: Text('사유')),
                    DataColumn(label: Text('등록일')),
                    DataColumn(label: Text('상태')),
                    DataColumn(label: Text('액션')),
                  ],
                  rows: reports.isEmpty
                      ? [
                          DataRow(cells: [
                            DataCell(Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                '신고된 채팅 메시지가 없습니다.',
                                style: TextStyle(color: Color(0xFF666666)),
                              ),
                            )),
                            ...List.generate(6, (_) => DataCell(Container())),
                          ])
                        ]
                      : reports.map((r) {
                          return DataRow(cells: [
                            DataCell(Text('${r.id}')),
                            DataCell(Text(r.reporter)),
                            DataCell(Text('${r.messageId}')),
                            DataCell(Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reasonLabel(r.reason),
                                style: TextStyle(fontSize: 12, color: Color(0xFF495057)),
                              ),
                            )),
                            DataCell(Text(
                              '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')} ${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 13),
                            )),
                            DataCell(Text(
                              statusLabel(r.status),
                              style: TextStyle(
                                color: statusColor(r.status),
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                            DataCell(
                              r.status == 'PENDING'
                                  ? Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => processStatus(r.id, 'RESOLVED'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF28A745),
                                            foregroundColor: Colors.black,
                                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: Text('완료'),
                                        ),
                                        SizedBox(width: 4),
                                        ElevatedButton(
                                          onPressed: () => processStatus(r.id, 'REJECTED'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFDC3545),
                                            foregroundColor: Colors.black,
                                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: Text('거부'),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: processedBg(r.status),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        r.status == 'RESOLVED' ? '처리 완료' : '처리 거부',
                                        style: TextStyle(
                                          color: processedFg(r.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                            ),
                          ]);
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
