import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:net_2026/login_screen.dart';
import 'package:net_2026/module_b/add_product_screen.dart';
import 'package:net_2026/module_b/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {

  //화면을 누른 것에 맞게 이동시켜주는 함수
  void nextPage(int index) {
    switch (index) {
      case 0: //알림 화면 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
        break;
      case 1: //내 등록 상품 이동 페이지
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen())
        );
        break;
      case 2:
        //판매 내역 페이지 이동
        break;
      case 3:
        //구매 내역 페이지 이동
        break;
      case 4:
        //고객센터 페이지 이동
        break;
      case 5:
        //앱 정보 페이지 이동

    }
  }

  List<Map<String, dynamic>> settingComponent = [
    {'icon': Icons.add, 'title': '알림'},
    {'icon': Icons.inventory_2_outlined, 'title': '내 등록 상품'},
    {'icon': Icons.shopping_bag_outlined, 'title': '판매 내역'},
    {'icon': Icons.history, 'title': '구매 내역'},
    {'icon': Icons.help_outline, 'title': '고객센터'},
    {'icon': Icons.info_outline, 'title': '앱 정보'},
  ];

  String? name;
  String? email;

  // 로컬에 있는 이름과 이메일을 가져와서 화면에 반영하는 함수
  Future<void> getLocalData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? localName = prefs.getString('name');
    final String? localEmail = prefs.getString('email');

    if (mounted) {
      setState(() {
        name = localName;
        email = localEmail;
      });
    }
  }

  //사용자의 인증 데이터 삭제하는 부분(이메일과 비밀번호만 삭제함)

  Future<void> popLoginData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');

    //지워지는지 테스트용 프린트
    // print("삭제 완료");
  }


  @override
  void initState() {
    super.initState();
    getLocalData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 상단 마이페이지 텍스트
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(
                    '마이페이지',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 2. 프로필 정보 표시 카드
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        // 프로필 아바타
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFF554829),
                          child: Icon(
                            Symbols.person,
                            color: Color(0xFFDC9D4B),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 사용자 이름 및 이메일 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? '사용자',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                email ?? '이메일 정보 없음',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              //설정 컴포넌트 요소들
              SizedBox(
                height: 400,
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: settingComponent.length,
                  itemBuilder: (context, index) {
                    final item = settingComponent[index];
                    final IconData icon = item['icon'];
                    final String text = item['title'];
                    bool isDivider = (index + 1) % 2 == 0
                        ? true
                        : false; //2번째면 디바이더를 그리기 위한 불 변수

                    return Column(
                      children: [
                        ListTile(
                          // 왼쪽 아이콘
                          leading: Icon(
                            icon,
                            color: Colors.white,
                          ),
                          // 중앙 텍스트
                          title: Text(
                            text,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          // 오른쪽 이동 화살표
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white54,
                          ),
                          onTap: () {
                            nextPage(index);
                          },
                        ),
                        if (isDivider)
                          Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            thickness: 1.0,
                            height: 1.0,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: Colors.red,
                        ),
                        minimumSize: Size(double.infinity, 50)
                    ),

                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        // 다이얼로그 바깥을 눌러도 안 닫히게 설정 (선택 사항)
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Color(0xFF1E1E1E),
                            title: const Text(
                              '확인',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white
                              ),
                            ),
                            content: const Text(
                              '정말로 삭제하시겠습니까?',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16
                              ),
                            ),
                            actions: [
                              // '아니오' 버튼
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(
                                      false); // false 값 전달하며 닫기
                                },
                                child: const Text('아니오'),
                              ),
                              // '예' 버튼
                              TextButton(
                                onPressed: () {
                                  //로그인 관련 정보를 삭제하는 로컬에서 삭제하는 함수
                                  popLoginData();

                                  //모든 화면을 메모리에서 삭제 시킨 후 받기
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (
                                        context) => const LoginScreen()),
                                        (route) => false,
                                  );
                                },
                                child: const Text('예'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red
                      ),
                    )
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}