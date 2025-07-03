import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/index.dart';
import 'pages/mypage.dart';
import 'pages/friends.dart';
import 'pages/setting.dart';
import 'pages/inquiry_form.dart';
import 'pages/inquiry_list.dart';
import 'pages/chat.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_member_page.dart';
import 'pages/admin_report_page.dart';
import 'pages/admin_chatreport_page.dart';
import 'pages/admin_inquiry_page.dart';
import 'pages/admin_chatlog.dart'; // ← 추가

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '서담',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/auth/login',
      routes: {
        '/auth/login': (context) => const LoginPage(),
        '/auth/signup': (context) => const SignupPage(),
        '/index': (context) => const IndexPage(),
        '/mypage': (context) => const MyPageScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/setting': (context) => const SettingsScreen(),
        '/inquiry_form': (context) => const InquiryFormScreen(),
        '/inquiry_list': (context) => const InquiryListScreen(),
        '/chat': (context) => ChatListScreen(),
        '/admin/dashboard': (context) => AdminDashboardPage(),
        '/admin/members': (context) => AdminMemberPage(),
        '/admin/reports': (context) => AdminReportPage(),
        '/admin/chat-reports': (context) => AdminChatreportPage(),
        '/admin/inquiries': (context) => Admininquirypage(),
        '/admin/chatlog': (context) => AdminChatlog(), // ← 추가!
      },
    );
  }
}
