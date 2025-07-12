import 'dart:convert';
import 'dart:math';  // substring 용
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ─── Data Model ───────────────────────────────────────────────
class ChatLog {
  final String sentAt;           // ISO 문자열 ("2025-07-06 14:23:45")
  final String senderNickname;   // senderNickname
  final String content;          // content
  final bool isDeleted;          // isDeleted

  ChatLog({
    required this.sentAt,
    required this.senderNickname,
    required this.content,
    required this.isDeleted,
  });

  factory ChatLog.fromJson(Map<String, dynamic> json) {
    return ChatLog(
      sentAt: json['sentAt'] as String,
      senderNickname: json['senderNickname'] as String,
      content: json['content'] as String,
      isDeleted: json['isDeleted'] as bool,
    );
  }
}

// ─── Main Widget ──────────────────────────────────────────────
class AdminChatlog extends StatefulWidget {
  @override
  State<AdminChatlog> createState() => _AdminChatlogState();
}

class _AdminChatlogState extends State<AdminChatlog> {
  final _storage = const FlutterSecureStorage();
  List<ChatLog> allChats = [];
  String userFilter = '';
  String periodFilter = '';
  bool isLoading = true;
  String? _error;

  // --- 페이지네이션 관련 변수 ---
  int currentPage = 0;
  final int pageSize = 20;

  @override
  void initState() {
    super.initState();
    fetchChatLogs();
  }

  Future<void> fetchChatLogs() async {
    print('▶️ fetchChatLogs 시작');
    setState(() {
      isLoading = true;
      _error = null;
      currentPage = 0; // 새로 불러올 때 첫 페이지로
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final uri = Uri.parse('http://192.168.0.53:8080/api/admin/chatlogs');
      print('  • GET $uri');

      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final bodyText = utf8.decode(response.bodyBytes);
      print('  • 상태: ${response.statusCode}');
      print('  • 본문(최대100자): ${bodyText.substring(0, min(100, bodyText.length))}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(bodyText) as List<dynamic>;
        setState(() {
          allChats = data
              .map((e) => ChatLog.fromJson(e as Map<String, dynamic>))
              .toList();
        });
        print('✅ ${allChats.length}개 채팅 로드 완료');
      } else {
        setState(() {
          _error = '채팅 로그 불러오기 실패: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('❌ fetchChatLogs 예외: $e');
      setState(() {
        _error = '네트워크 오류: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
      print('▶️ fetchChatLogs 종료');
    }
  }

  List<ChatLog> get filteredChats {
    final now = DateTime.now();
    return allChats.where((chat) {
      if (userFilter.isNotEmpty &&
          !chat.senderNickname.toLowerCase().contains(userFilter.toLowerCase()) &&
          !chat.content.toLowerCase().contains(userFilter.toLowerCase())) {
        return false;
      }
      if (periodFilter.isNotEmpty) {
        final dt = DateTime.tryParse(chat.sentAt.replaceAll(' ', 'T'));
        if (dt != null) {
          final d = now.difference(dt).inDays;
          if (periodFilter == '1' && d > 0) return false;
          if (periodFilter == '3' && d > 2) return false;
          if (periodFilter == '7' && d > 6) return false;
        }
      }
      return true;
    }).toList();
  }

  List<ChatLog> get pagedChats {
    final start = currentPage * pageSize;
    final end = min(start + pageSize, filteredChats.length);
    if (start >= filteredChats.length) return [];
    return filteredChats.sublist(start, end);
  }

  int get totalPages =>
      (filteredChats.length / pageSize).ceil();

  Color statusColor(bool isDeleted) =>
      isDeleted ? const Color(0xFFD32F2F) : const Color(0xFF24A148);

  String statusLabel(bool isDeleted) =>
      isDeleted ? '삭제됨' : '정상';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    Widget content;
    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    } else {
      content = _buildMainContent();
    }

    return isMobile
        ? Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: const Color(0xFF232323),
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('채팅 로그 관리', style: TextStyle(color: Colors.white)),
            ),
            drawer: SizedBox(
              width: 200,
              child: AdminSidebar(activeRoute: '/admin/chatlog', isDrawer: true),
            ),
            body: content,
          )
        : Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            body: Row(
              children: [
                AdminSidebar(activeRoute: '/admin/chatlog', isDrawer: false),
                Expanded(child: content),
              ],
            ),
          );
  }

  Widget _buildMainContent() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('채팅 로그 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '닉네임 또는 메시지 입력',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() {
                      userFilter = v.trim();
                      currentPage = 0; // 필터 변경시 첫 페이지로
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: periodFilter.isEmpty ? null : periodFilter,
                  hint: const Text('전체 기간'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('전체')),
                    DropdownMenuItem(value: '1', child: Text('오늘')),
                    DropdownMenuItem(value: '3', child: Text('3일')),
                    DropdownMenuItem(value: '7', child: Text('7일')),
                  ],
                  onChanged: (v) => setState(() {
                    periodFilter = v ?? '';
                    currentPage = 0; // 필터 변경시 첫 페이지로
                  }),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF0F0F0)),
                          columns: const [
                            DataColumn(label: Text('송신자')),
                            DataColumn(label: Text('내용')),
                            DataColumn(label: Text('상태')),
                          ],
                          rows: pagedChats.map((chat) {
                            return DataRow(
                              cells: [
                                DataCell(Text(chat.senderNickname)),
                                DataCell(ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 300),
                                  child: Text(chat.content, overflow: TextOverflow.ellipsis),
                                )),
                                DataCell(Text(
                                  statusLabel(chat.isDeleted),
                                  style: TextStyle(color: statusColor(chat.isDeleted)),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPagination(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 0
              ? () => setState(() => currentPage--)
              : null,
        ),
        Text('${currentPage + 1} / $totalPages',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages - 1
              ? () => setState(() => currentPage++)
              : null,
        ),
      ],
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
      color: const Color(0xFF232323),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('관리자',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
          const Divider(color: Colors.white24, thickness: 1, height: 8),
          ...menuItems.map((item) => SidebarLink(
                icon: item['icon'] as String,
                label: item['label'] as String,
                route: item['route'] as String,
                active: activeRoute == item['route'],
                isDrawer: isDrawer,
              )),
          const Divider(color: Colors.white24, thickness: 1, height: 8),
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
  const SidebarLink({
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Text(icon, style: TextStyle(fontSize: 18, color: active ? Color(0xFF4FC3F7) : Colors.white)),
      title: Text(label, style: TextStyle(
        color: active ? Color(0xFF4FC3F7) : Colors.white,
        fontSize: 15,
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
      )),
      selected: active,
      selectedTileColor: const Color(0xFF30333A),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: const Text('📕', style: TextStyle(fontSize: 18, color: Color(0xFFFF6666))),
      title: const Text('로그아웃', style: TextStyle(color: Color(0xFFFF6666), fontSize: 15)),
      onTap: () {
        if (isDrawer) Navigator.pop(context);
        // 로그아웃 로직 필요시 여기에 추가
      },
    );
  }
}
