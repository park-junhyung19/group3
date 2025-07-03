import 'package:flutter/material.dart';

// 신고 데이터 예시
class Report {
  final int id;
  final String reporter;
  final String type;
  final int targetId;
  final String reason;
  final DateTime createdAt;
  String status; // "PENDING", "RESOLVED", "REJECTED"

  Report({
    required this.id,
    required this.reporter,
    required this.type,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    required this.status,
  });
}

class AdminReportPage extends StatefulWidget {
  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  // 샘플 데이터
  List<Report> reports = [
    Report(
      id: 1,
      reporter: 'user123',
      type: 'POST',
      targetId: 45,
      reason: 'spam',
      createdAt: DateTime(2025, 6, 30, 23, 49),
      status: 'PENDING',
    ),
    Report(
      id: 2,
      reporter: 'alice',
      type: 'COMMENT',
      targetId: 88,
      reason: 'harassment',
      createdAt: DateTime(2025, 6, 29, 10, 12),
      status: 'RESOLVED',
    ),
    Report(
      id: 3,
      reporter: 'bob',
      type: 'POST',
      targetId: 99,
      reason: 'other',
      createdAt: DateTime(2025, 6, 28, 15, 30),
      status: 'REJECTED',
    ),
  ];

  // 사유 코드 → 한글 변환
  String reasonLabel(String code) {
    switch (code) {
      case 'spam': return '스팸 또는 광고';
      case 'harassment': return '괴롭힘 또는 혐오 발언';
      case 'inappropriate': return '부적절한 콘텐츠';
      case 'copyright': return '저작권 침해';
      case 'false_info': return '거짓 정보';
      case 'other': return '기타';
      default: return code;
    }
  }

  // 상태별 색상
  Color statusColor(String status) {
    switch (status) {
      case 'PENDING': return Color(0xFFFF6B35);
      case 'RESOLVED': return Color(0xFF28A745);
      case 'REJECTED': return Color(0xFFDC3545);
      default: return Colors.grey;
    }
  }

  // 상태별 텍스트
  String statusLabel(String status) {
    switch (status) {
      case 'PENDING': return '대기';
      case 'RESOLVED': return '완료';
      case 'REJECTED': return '거부';
      default: return status;
    }
  }

  // 상태 변경 함수
  void patchStatus(int id, String newStatus) {
    setState(() {
      final idx = reports.indexWhere((r) => r.id == id);
      if (idx != -1) reports[idx].status = newStatus;
    });
    // 실제 API 연동은 여기서 처리
    // 예: await api.patchReportStatus(id, newStatus);
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
              title: Text('신고 관리', style: TextStyle(color: Colors.white)),
            ),
            drawer: SizedBox(
              width: 200,
              child: AdminSidebar(
                activeRoute: '/admin/reports',
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
                  activeRoute: '/admin/reports',
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
            Text('신고 목록', style: TextStyle(fontSize: 28, color: Color(0xFF232323), fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('신고자')),
                    DataColumn(label: Text('타입')),
                    DataColumn(label: Text('대상ID')),
                    DataColumn(label: Text('사유')),
                    DataColumn(label: Text('등록일')),
                    DataColumn(label: Text('상태')),
                    DataColumn(label: Text('액션')),
                  ],
                  rows: reports.map((r) {
                    return DataRow(cells: [
                      DataCell(Text('${r.id}')),
                      DataCell(Text(r.reporter)),
                      DataCell(Text(r.type)),
                      DataCell(Text('${r.targetId}')),
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
                      DataCell(Row(
                        children: [
                          ElevatedButton(
                            onPressed: r.status == 'PENDING'
                                ? () => patchStatus(r.id, 'RESOLVED')
                                : null,
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
                            onPressed: r.status == 'PENDING'
                                ? () => patchStatus(r.id, 'REJECTED')
                                : null,
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
                      )),
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
