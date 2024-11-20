import 'package:provider/provider.dart';
import 'IdProvider.dart';
import 'signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'firebase/firesbase_init.dart'; // Firebase 초기화 관리 파일

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 바인딩 초기화
  await FirebaseInit().initializeFirebase(); // Firebase 초기화
  runApp(
    ChangeNotifierProvider(
      create: (context)=> Idprovider(),
      child: const MyApp(),
      ),
    ); // 앱 실행
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My InterViewer ', // 앱 제목
      theme: ThemeData(
        primarySwatch: Colors.blue, // 앱 테마
      ),
      home: const LoginSignupScreen(), // 시작 화면
    );
  }
}
