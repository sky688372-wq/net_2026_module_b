import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:net_2026/login_screen.dart';
import 'package:net_2026/main_page_screen.dart';

// 1. 전역 RouteObserver 선언 (화면 전환을 감지하는 감시자)
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  // 화면 세로 방향으로 고정시키는 부분
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      // 2. navigatorObservers에 등록
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainPageScreen(),
    );
  }
}