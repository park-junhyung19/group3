import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/index.dart';
import 'pages/mypage.dart';
import 'pages/friends.dart';
import 'setting/setting.dart';
import 'setting/change_password.dart';
import 'setting/change_email.dart';
import 'setting/change_phone.dart';
import 'setting/confirm_password.dart';
import 'pages/inquiry_form.dart';
import 'pages/inquiry_list.dart';
import 'pages/chat.dart';
import 'pages/post_form.dart';   // ✅ 글쓰기 화면
import 'pages/post_show.dart';  // ✅ 글 목록 화면
import 'pages/shorts_page.dart'; // ✅ 숏폼 페이지 추가 (이 줄만 새로 추가)

// 관리자 페이지
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_member_page.dart';
import 'pages/admin_report_page.dart';
import 'pages/admin_chatreport_page.dart';
import 'pages/admin_inquiry_page.dart';
import 'pages/admin_chatlog.dart';
import 'pages/admin_login_page.dart';

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
        // 인증
        '/auth/login':      (context) => const LoginPage(),
        '/auth/signup':     (context) => const SignupPage(),

        // 일반 사용자
        '/index':           (context) => const IndexPage(),
        '/mypage':          (context) => const MyPageScreen(),
        '/friends':         (context) => const FriendsScreen(),
        '/setting':         (context) => const SettingsScreen(),
        '/changePassword':  (context) => const ChangePasswordPage(),
        '/changeEmail':     (context) => const ChangeEmailPage(),
        '/confirmPassword': (context) => const ConfirmPasswordPage(),
        '/changePhone':     (context) => const ChangePhonePage(),
        '/inquiry_form':    (context) => const InquiryFormScreen(),
        '/inquiry_list':    (context) => const InquiryListScreen(),
        '/chat':            (context) => ChatListScreen(),
        '/posts/new':       (context) => const PostFormScreen(),
        '/posts':           (context) => PostShowPage(),
        '/shorts':          (context) => const ShortsPage(), // ✅ 숏폼 페이지 라우트 등록

        // 관리자
        '/admin/login':        (context) => AdminLoginPage(),
        '/admin/dashboard':    (context) => AdminDashboardPage(),
        '/admin/members':      (context) => AdminMemberPage(),
        '/admin/reports':      (context) => AdminReportPage(),
        '/admin/chat-reports': (context) => AdminChatreportPage(),
        '/admin/inquiries':    (context) => AdminInquiryPage(),
        '/admin/chatlog':      (context) => AdminChatlog(),
      },
    );
  }
}
