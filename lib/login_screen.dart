import 'dart:convert';
import 'dart:ui'; // ImageFilter 사용을 위해 필수
import 'package:flutter/material.dart';
import 'package:net_2026/main_page_screen.dart';
import 'package:net_2026/sign_up_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {


  //이메일, 이름을 저장히는 함수 -> 나중에 마이페이지 표시할 때 쓸 예정임
  Future<void> setLaterData() async {
    //{"success":true,"message":"로그인 성공","data":{"token":"vinyl-token-1786517757873","user":{"id":1,"email":"test@example.com","name":"홍길동"}}}
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('email', _emailCtrl.text);
    prefs.setString('name', _passwordCtrl.text);
  }

  bool _isPasswordHidden = true; // 기본적으로 가림 처리

  // 텍스트 필드 컨트롤러
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // 스낵바 출력 공통 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 유효성 검사 함수
  bool _validateInputs() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // 1. 이메일 입력 여부 검사
    if (email.isEmpty) {
      _showSnackBar('이메일을 입력해주세요.');
      return false;
    }

    // 2. 이메일 형식 검사
    final isEmailValid = email.contains('@') &&
        email.contains('.') &&
        !email.contains('.@');

    if (!isEmailValid) {
      _showSnackBar('올바른 이메일 형식을 입력해주세요.');
      return false;
    }

    // 3. 비밀번호 입력 여부 검사
    if (password.isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요.');
      return false;
    }

    // 모든 조건 통과 시 true 반환 (통과 시엔 스낵바를 띄우지 않음)
    return true;
  }


  //테스트 이메일 : test@example.com
  //테스트 비밀번호 : Test1234!

  // 통신 함수
  Future<void> tryLogin() async {
    // 유효성 검사 통과 못하면 중단
    if (!_validateInputs()) {
      return;
    }

    final url = "https://connexChat-server.onrender.com/vinyl/auth/login";
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setInt('userId', data['data']['user']['id']); //유저 아이디를 로컬에 저장함

        _showSnackBar("로그인 성공");

        if(!mounted) {
          return;
        }

        setLaterData(); //이메일, 유저 id, 비밀번호 저장
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPageScreen()),
        );
      } else {
        // API 명세서 에러 메시지 파싱
        String errorMessage = "로그인 실패";

        if (data['errors'] != null &&
            data['errors'] is List &&
            (data['errors'] as List).isNotEmpty) {
          errorMessage = data['errors'][0]['message'] ?? '로그인 실패';
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }

        _showSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("오류가 발생했습니다: $e");
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 1. 상단 250px 영역
            SizedBox(
              width: double.infinity,
              height: 250,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.3, sigmaY: 2.3),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.0001),
                        ),
                      ),
                    ),
                    Center(
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo_horizontal.png',
                              width: 180,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vinyl Record Secondhand Marketplace',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. 타이틀 문구 영역
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "로그인",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '계정으로 로그인하여 다양한 서비스를 이용하세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. 입력 폼 및 로그인 버튼 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // 이메일 텍스트 필드
                  TextField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "이메일을 입력해주세요.",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 비밀번호 텍스트 필드
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _isPasswordHidden,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "비밀번호를 입력해주세요.",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.white70,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                        child: Icon(
                          _isPasswordHidden
                              ? Icons.visibility_off
                              : Icons.remove_red_eye_sharp,
                          color: Colors.white70,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _showSnackBar('현재 준비중인 기능입니다.');
                        },
                        child: Text(
                          '비밀번호를 잊으셨나요?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        tryLogin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffdaa84d),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "로그인",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.3),
                      thickness: 1,
                      endIndent: 15,
                    ),
                  ),
                ),
                Text(
                  '또는',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.3),
                      thickness: 1,
                      indent: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '계정이 없으신가요?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      '회원 가입',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffdaa84d),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}