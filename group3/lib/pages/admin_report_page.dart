import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------- 신고 관리 페이지 ----------------

class AdminReportPage extends StatefulWidget {
  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  List<Map<String, dynamic>> reports = [];
  final String apiUrl = 'http://192.168.0.53:8080/api/admin/reports';
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      print('[fetchReports] JWT 토큰: $token');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );
      print('신고 목록 응답 status: ${response.statusCode}');
      print('신고 목록 응답 body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains('application/json') == true) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          reports = data.cast<Map<String, dynamic>>();
        });
      } else {
        print('❌ 신고 목록 불러오기 실패: ${response.statusCode}');
        print('❌ 응답 본문: ${response.body}');
        setState(() {
          reports = [];
        });
      }
    } catch (e) {
      print('❌ 신고 목록 로드 중 예외 발생: $e');
      setState(() {
        reports = [];
      });
    }
  }

  // 사유 코드 → 한글 변환
  String reasonLabel(String code) {
    switch (code) {
      case 'spam':
        return '스팸 또는 광고';
      case 'harassment':
        return '괴롭힘 또는 혐오 발언';
      case 'inappropriate':
        return '부적절한 콘텐츠';
      case 'copyright':
        return '저작권 침해';
      case 'false_info':
        return '거짓 정보';
      case 'other':
        return '기타';
      default:
        return code;
    }
  }

  // 상태별 색상
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

  // 상태별 텍스트
  String statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return '대기';
      case 'RESOLVED':
        return '완료';
      case 'REJECTED':
        return '거부';
      default:
        return status;
    }
  }

  // 상태 변경 함수 (PATCH 요청)
  Future<void> patchStatus(int id, String newStatus) async {
    final uri = Uri.parse('$apiUrl/$id');
    final token = await _storage.read(key: 'jwt_token');
    print('[patchStatus] JWT 토큰: $token');
    // UI 즉시 반영
    setState(() {
      final idx = reports.indexWhere((r) => r['id'] == id);
      if (idx != -1) reports[idx]['status'] = newStatus;
    });
    // 서버에 PATCH 요청
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': newStatus}),
    );
    print('상태 변경 응답 status: ${response.statusCode}');
    print('상태 변경 응답 body: ${response.body}');
    if (response.statusCode != 200) {
      // 실패 시 롤백
      setState(() {
        final idx = reports.indexWhere((r) => r['id'] == id);
        if (idx != -1) reports[idx]['status'] = 'PENDING';
      });
      print('❌ 상태 변경 실패: ${response.statusCode}');
      print('❌ 응답 본문: ${response.body}');
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
                AdminSidebar(activeRoute: '/admin/reports', isDrawer: false),
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
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('신고 목록',
                style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF232323),
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('신고자')),
                    DataColumn(label: Text('대상ID')),
                    DataColumn(label: Text('사유')),
                    DataColumn(label: Text('등록일')),
                    DataColumn(label: Text('상태')),
                    DataColumn(label: Text('액션')),
                  ],
                  rows: reports.map((r) {
                    final status = r['status'] as String;
                    return DataRow(cells: [
                      DataCell(Text('${r['id']}')),
                      DataCell(Text(r['reporter'] ?? '-')),
                      DataCell(Text('${r['targetId']}')),
                      DataCell(Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reasonLabel(r['reason'] ?? ''),
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF495057)),
                        ),
                      )),
                      DataCell(Text(
                        (r['createdAt'] != null)
                            ? DateTime.parse(r['createdAt'])
                                .toString()
                                .substring(0, 16)
                            : '-',
                        style: TextStyle(fontSize: 13),
                      )),
                      DataCell(Text(
                        statusLabel(status),
                        style: TextStyle(
                          color: statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      DataCell(Row(
                        children: [
                          ElevatedButton(
                            onPressed: status == 'PENDING'
                                ? () => patchStatus(r['id'] as int, 'RESOLVED')
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF28A745),
                              foregroundColor: Colors.black,
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text('완료'),
                          ),
                          SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: status == 'PENDING'
                                ? () => patchStatus(r['id'] as int, 'REJECTED')
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFDC3545),
                              foregroundColor: Colors.black,
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
              child: Text('관리자',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
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
      leading:
          Text(icon, style: TextStyle(fontSize: 18, color: active ? Color(0xFF4FC3F7) : Colors.white)),
      title: Text(label,
          style: TextStyle(
              color: active ? Color(0xFF4FC3F7) : Colors.white,
              fontSize: 15,
              fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      selected: active,
      selectedTileColor: Color(0xFF30333A),
      onTap: () {
        if (!active) {
          if (isDrawer) Navigator.pop(context);
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
        if (isDrawer) Navigator.pop(context);
        // TODO: 실제 로그아웃 로직 구현
      },
    );
  }
}
