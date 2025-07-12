import 'dart:convert';
import 'dart:math';  // ← 이 줄을 추가하세요
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// 1:1 문의 모델
class Inquiry {
  final int id;
  final int userId;
  final String title;
  final String content;
  String status; // '미답변' 또는 '답변완료'
  final DateTime createdAt;
  String? reply;

  Inquiry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    this.reply,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reply: json['reply'] as String?,
    );
  }
}

class AdminInquiryPage extends StatefulWidget {
  @override
  State<AdminInquiryPage> createState() => _AdminInquiryPageState();
}

class _AdminInquiryPageState extends State<AdminInquiryPage> {
  static const String _baseUrl = 'http://192.168.0.53:8080/api/admin/inquiries';
  final _storage = const FlutterSecureStorage();
  List<Inquiry> inquiries = [];
  final Map<int, TextEditingController> replyControllers = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
  }

  Future<void> _fetchInquiries() async {
    final start = DateTime.now();
    print('▶️ _fetchInquiries 시작');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      print('  • token 읽음: $token');
      final uri = Uri.parse(_baseUrl);
      print('  • GET $uri');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

      final res = await http.get(uri, headers: headers);
      final bodyText = utf8.decode(res.bodyBytes);
      print('  • 응답 상태: ${res.statusCode}');
      print('  • 응답 본문 (100자까지): ${bodyText.substring(0, min(100, bodyText.length))}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(bodyText);
        final loaded = data
            .map((e) => Inquiry.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          inquiries = loaded;
          _loading = false;
        });
        print('✅ ${inquiries.length}개의 문의 로드 완료 (${DateTime.now().difference(start)})');
      } else {
        setState(() {
          _error = '문의 조회 실패: ${res.statusCode}';
          _loading = false;
        });
        print('❌ _fetchInquiries 실패: HTTP ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류: $e';
        _loading = false;
      });
      print('❌ _fetchInquiries 예외: $e');
    }
  }

  Future<void> _replyToInquiry(Inquiry inq, String text) async {
    final token = await _storage.read(key: 'jwt_token');
    final uri = Uri.parse('$_baseUrl/${inq.id}/reply');
    print('▶️ _replyToInquiry: id=${inq.id}, 텍스트="$text"');
    print('  • POST $uri');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    final res = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'reply': text}),
    );
    print('  • 응답 상태: ${res.statusCode}');

    if (res.statusCode == 200) {
      setState(() {
        inq.reply = text;
        inq.status = '답변완료';
      });
      print('✅ 문의 ${inq.id} 답변 저장 성공');
    } else {
      print('❌ 문의 ${inq.id} 답변 저장 실패: HTTP ${res.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('답변 저장 실패: ${res.statusCode}')),
      );
    }
  }

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
    Widget body;
    if (_loading) {
      body = Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text('오류: $_error', style: TextStyle(color: Colors.red)));
    } else {
      body = _buildMainContent();
    }

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
            body: body,
          )
        : Scaffold(
            backgroundColor: Color(0xFFF7F7F7),
            body: Row(
              children: [
                AdminSidebar(
                  activeRoute: '/admin/inquiries',
                  isDrawer: false,
                ),
                Expanded(child: body),
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
            Text('1:1 문의 관리',
                style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF232323),
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 1200),
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor:
                        MaterialStateProperty.all(Color(0xFFF0F2F5)),
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('사용자 ID')),
                      DataColumn(label: Text('제목')),
                      DataColumn(label: Text('내용')),
                      DataColumn(label: Text('상태')),
                      DataColumn(label: Text('작성일')),
                      DataColumn(label: Text('답변')),
                    ],
                    rows: inquiries.map((inq) {
                      replyControllers.putIfAbsent(
                          inq.id, () => TextEditingController());
                      return DataRow(cells: [
                        DataCell(Text('${inq.id}')),
                        DataCell(Text('${inq.userId}')),
                        DataCell(Text(inq.title)),
                        DataCell(Tooltip(
                          message: inq.content,
                          child: Container(
                            width: 200,
                            child: Text(
                              inq.content,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg(inq.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inq.status,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor(inq.status),
                                fontSize: 15),
                          ),
                        )),
                        DataCell(Text(
                          '${inq.createdAt.year}-${inq.createdAt.month.toString().padLeft(2, '0')}-${inq.createdAt.day.toString().padLeft(2, '0')} '
                          '${inq.createdAt.hour.toString().padLeft(2, '0')}:${inq.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 13),
                        )),
                        DataCell(
                          inq.status == '답변완료'
                              ? Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8F8F8),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border(
                                      left: BorderSide(
                                          color: Color(0xFF4FC3F7), width: 4),
                                    ),
                                  ),
                                  child: Text(
                                    inq.reply ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF333333)),
                                  ),
                                )
                              : _buildReplyForm(inq),
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

  Widget _buildReplyForm(Inquiry inq) {
    final controller = replyControllers[inq.id]!;
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(vertical: 8),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                _replyToInquiry(inq, text);
                controller.clear();
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
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Text(icon,
          style: TextStyle(
              fontSize: 18,
              color: active ? Color(0xFF4FC3F7) : Colors.white)),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading:
          Text('📕', style: TextStyle(fontSize: 18, color: Color(0xFFFF6666))),
      title: Text('로그아웃',
          style: TextStyle(color: Color(0xFFFF6666), fontSize: 15)),
      onTap: () {
        if (isDrawer) Navigator.pop(context);
      },
    );
  }
}
