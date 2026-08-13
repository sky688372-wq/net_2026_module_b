import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:net_2026/main.dart' as app;
import 'helpers.dart';

void main() {
  // 통합 테스트 바인딩 초기화
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("FORM 1.1 로그인 유효성 / 탐색 필터 / 관심 상품", (WidgetTester tester) async {
    // 1. 테스트 실행 전 로컬 저장소 초기화
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 2. 어플리케이션 실행 스텝
    await step(
      tester,
      1,
      "어플리케이션 실행 및 로그인 화면 확인",
          () async {
        app.main();
      },
      verify: () {
        expect(find.text('로그인'), findsWidgets);
      },
    );

    final emailField = find.byType(TextField).at(0);
    final passField = find.byType(TextField).at(1);
    final loginButton = find.widgetWithText(ElevatedButton, '로그인');

    // 로그인 입력 및 버튼 클릭 헬퍼 함수
    Future<void> tryLogin(String email, String password) async {
      await tester.enterText(emailField, email);
      await tester.enterText(passField, password);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    }

    //잘목된 이메일 형식으로 로그인 시도
    await step(tester, 2, "잘못된 이메일 로그인 시도", () async {
      await tester.enterText(emailField, "아_주_잘_못_된_형_식");
      await tester.enterText(passField, "Test1234!");
      await tester.tap(loginButton);
    });

    //잘못된 비밀번호 형식으로 로그인 시도
    await step(tester, 3, "잘못된 비밀번호 로그인 시도", () async {
      await tester.enterText(passField, "1234");
      await tester.tap(loginButton);
    },);

    //정상 로그인 시도
    await step(tester, 4, "정상 로그인 시도", () async {
      await tester.enterText(emailField, "test@example.com");
      await tester.enterText(passField, "Test1234!");
      await tester.tap(loginButton);
      await waitFor(tester, find.text("오늘의 추천 바이닐"));
    },);



    // 하단 네비게이션의 탐색 탭을 클릭 시도
    await step(tester, 5, "탐색 탭 클릭 시도", () async {
      await tester.tap(find.text("탐색"));
      await waitFor(tester, find.textContaining("검색 결과"));
    },);
  });
}