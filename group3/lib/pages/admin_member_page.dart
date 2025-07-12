import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AdminMemberPage extends StatefulWidget {
  @override
  State<AdminMemberPage> createState() => _AdminMemberPageState();
}

class _AdminMemberPageState extends State<AdminMemberPage> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> members = [];
  String search = '';

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    final token = await storage.read(key: 'jwt_token');
    print('[fetchMembers] JWT 토큰: $token');
    if (token == null || token.isEmpty) {
      print('❌ 토큰 없음. 로그인 필요');
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.0.53:8080/api/admin/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('[fetchMembers] status: ${response.statusCode}');
    print('[fetchMembers] body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        members = data.cast<Map<String, dynamic>>();
      });
    } else {
      print('❌ 사용자 목록 불러오기 실패: ${response.statusCode}');
      print('❌ 응답 본문: ${response.body}');
    }
  }

  Future<void> updateMemberStatus(String userId, String newStatus) async {
    final token = await storage.read(key: 'jwt_token');
    print('[updateMemberStatus] JWT 토큰: $token');
    if (token == null || token.isEmpty) {
      print('❌ 토큰 없음. 로그인 필요');
      return;
    }

    final url = 'http://192.168.0.53:8080/api/admin/members/$userId/status';
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );
      print('[updateMemberStatus] status: ${response.statusCode}');
      print('[updateMemberStatus] body: ${response.body}');
      if (response.statusCode == 200) {
        print('✅ 상태 변경 성공');
      } else {
        print('❌ 상태 변경 실패: ${response.statusCode}');
        print('❌ 응답 본문: ${response.body}');
        fetchMembers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상태 변경 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('❌ 상태 변경 예외: $e');
      fetchMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경 중 오류 발생')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = members.where((m) {
      final s = search.trim().toLowerCase();
      return s.isEmpty ||
          (m['nickname'] ?? '').toLowerCase().contains(s) ||
          (m['email'] ?? '').toLowerCase().contains(s);
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 700;

    return isMobile
        ? Scaffold(
            backgroundColor: Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: Color(0xFF232323),
              iconTheme: IconThemeData(color: Colors.white),
              title: Text('회원 관리', style: TextStyle(color: Colors.white)),
            ),
            drawer: SizedBox(
              width: 200,
              child: AdminSidebar(
                activeRoute: '/admin/members',
                isDrawer: true,
              ),
            ),
            body: _buildMainContent(filteredMembers),
          )
        : Scaffold(
            backgroundColor: Color(0xFFF7F7F7),
            body: Row(
              children: [
                AdminSidebar(
                  activeRoute: '/admin/members',
                  isDrawer: false,
                ),
                Expanded(child: _buildMainContent(filteredMembers)),
              ],
            ),
          );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> filteredMembers) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 900),
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
            Text('회원 관리', style: TextStyle(fontSize: 22, color: Color(0xFF232323), fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('회원 수: ${filteredMembers.length}', style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 18),
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '닉네임 또는 이메일 입력',
                      contentPadding: EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF4FC3F7)),
                      ),
                    ),
                    onChanged: (v) => setState(() => search = v),
                    onSubmitted: (v) => setState(() => search = v),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => fetchMembers(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF232323),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  ),
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text('새로고침', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            SizedBox(height: 18),
            // Table (세로 스크롤+가로 스크롤 모두 지원)
            Expanded(
              child: ListView(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 18,
                      headingRowColor: MaterialStateProperty.all(Color(0xFFF0F0F0)),
                      columns: [
                        DataColumn(label: Center(child: Text('닉네임'))),
                        DataColumn(label: Center(child: Text('이메일'))),
                        DataColumn(label: Center(child: Text('권한'))),
                        DataColumn(label: Center(child: Text('상태'))),
                      ],
                      rows: filteredMembers.map((user) {
                        return DataRow(cells: [
                          DataCell(Text(user['nickname'] ?? '')),
                          DataCell(Text(user['email'] ?? '')),
                          DataCell(RoleBadge(
                            role: user['role'] ?? '',
                            onChanged: (String? newRole) {
                              if (newRole != null) {
                                setState(() => user['role'] = newRole);
                                // TODO: 서버에 권한 변경 요청
                              }
                            },
                          )),
                          DataCell(StatusDropdown(
                            status: user['status'] ?? '',
                            onChanged: (String? newStatus) async {
                              if (newStatus != null && newStatus != user['status']) {
                                final oldStatus = user['status'];
                                setState(() => user['status'] = newStatus);
                                await updateMemberStatus(user['userId'].toString(), newStatus);
                              }
                            },
                          )),
                        ]);
                      }).toList(),
                    ),
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

// --------- 권한 뱃지 + 드롭다운 ---------
class RoleBadge extends StatelessWidget {
  final String role;
  final ValueChanged<String?> onChanged;
  RoleBadge({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;
    switch (role) {
      case 'ADMIN':
        bg = Color(0xFF232323);
        break;
      case 'EDITOR':
        bg = Color(0xFF4FC3F7);
        break;
      case 'SUPER':
        bg = Color(0xFFFF9800);
        break;
      default:
        bg = Color(0xFFE0E0E0);
        fg = Color(0xFF232323);
    }
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(value: 'USER', child: Text('USER')),
        PopupMenuItem(value: 'ADMIN', child: Text('ADMIN')),
        PopupMenuItem(value: 'EDITOR', child: Text('EDITOR')),
        PopupMenuItem(value: 'SUPER', child: Text('SUPER')),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(role, style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 13)),
            Icon(Icons.arrow_drop_down, color: fg, size: 18),
          ],
        ),
      ),
    );
  }
}

// --------- 상태 드롭다운 ---------
class StatusDropdown extends StatelessWidget {
  final String status;
  final ValueChanged<String?> onChanged;
  StatusDropdown({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'ACTIVE':
        bg = Color(0xFFE0FFE0);
        fg = Color(0xFF24A148);
        break;
      case 'SUSPENDED':
        bg = Color(0xFFFFF4E0);
        fg = Color(0xFFFF9800);
        break;
      case 'DELETED':
        bg = Color(0xFFFFE0E0);
        fg = Color(0xFFD32F2F);
        break;
      default:
        bg = Color(0xFFE0E0E0);
        fg = Color(0xFF232323);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          icon: Icon(Icons.arrow_drop_down, color: fg),
          style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 13),
          dropdownColor: Colors.white,
          onChanged: onChanged,
          items: [
            DropdownMenuItem(value: 'ACTIVE', child: Text('활성')),
            DropdownMenuItem(value: 'SUSPENDED', child: Text('정지')),
            DropdownMenuItem(value: 'DELETED', child: Text('탈퇴')),
          ],
        ),
      ),
    );
  }
}
