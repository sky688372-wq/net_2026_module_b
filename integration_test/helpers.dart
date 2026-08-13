import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 시나리오 테스트 단계를 명시적으로 기록하고 실행하기 위한 공통 헬퍼 함수
Future<void> step(
    WidgetTester tester,
    int no,
    String action,
    Future<void> Function() body, {
      void Function()? verify,
    }) async {
  // 1. 현재 수행 중인 단계 콘솔 출력 (디버깅용 로그)
  debugPrint('\n=== [Step $no] $action ===');

  // 2. 해당 단계의 본문(액션) 실행
  await body();

  // 3. UI 변경 사항 프레임 렌더링 및 애니메이션 완료 대기
  await setTle(tester);

  await Future.delayed(const Duration(milliseconds: 500));

  // 4. 검증 로직(verify)이 전달된 경우 실행
  if (verify != null) {
    verify();
  }
}

/// 애니메이션, 비동기 데이터 처리가 끝날 때까지 안정적으로 대기하는 헬퍼 함수
Future<void> setTle(
    WidgetTester tester, {
      Duration duration = const Duration(milliseconds: 100),
      Duration timeout = const Duration(seconds: 10),
    }) async {
  try {
    // 지정된 타임아웃 내에 UI가 안정화될 때까지 프레임 렌더링 대기
    await tester.pumpAndSettle(duration, EnginePhase.sendSemanticsUpdate, timeout);
  } catch (e) {
    debugPrint('pumpAndSettle 대기 중 타임아웃/예외 발생: $e');
  }
}

// 지정한 시간 동안 프레임을 지속적으로 갱신하며 대기하는 함수
Future<void> hold(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

// 특정 조건(Finder)을 만족하는 위젯이 나타날 때까지 대기하는 함수
Future<void> waitFor(WidgetTester tester, Finder finder, {int timeOut = 30}) async {
  final deadLine = DateTime.now().add(Duration(seconds: timeOut));
  while (DateTime.now().isBefore(deadLine)) {
    await tester.pump(const Duration(milliseconds: 300));
    await Future.delayed(const Duration(milliseconds: 300));
    if (tester.any(finder)) {
      return;
    }
  }
}