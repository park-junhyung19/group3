import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/index.dart'; // 최신 메인 페이지
import 'pages/mypage.dart'; // 마이페이지
import 'pages/friends.dart'; // 친구 관리
import 'pages/setting.dart'; // 설정
import 'pages/inquiry_form.dart'; // 1:1 문의하기
import 'pages/inquiry_list.dart'; // 1:1 문의 목록
import 'pages/chat.dart'; // ← chat.dart 파일 import
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
        '/index': (context) => const IndexPage(), // 메인 페이지
        '/mypage': (context) => const MyPageScreen(), // 마이페이지
        '/friends': (context) => const FriendsScreen(), // 친구 관리
        '/setting': (context) => const SettingsScreen(), // 설정
        '/inquiry_form': (context) => const InquiryFormScreen(), // 1:1 문의하기
          '/inquiry_list': (context) => const InquiryListScreen(), // ← 추가!
'/chat': (context) => ChatListScreen(),


      },
    );
  }
}
