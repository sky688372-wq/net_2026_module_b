import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:net_2026/detail_screen.dart';
import 'package:net_2026/module_b/notification_screen.dart';
import 'package:net_2026/module_b/wishlist_screen.dart';
import 'package:net_2026/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_animated_indexed_stack/easy_animated_indexed_stack.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MainPageScreen extends StatefulWidget {
  const MainPageScreen({super.key});

  @override
  State<MainPageScreen> createState() => _MainPageScreenState();
}

class _MainPageScreenState extends State<MainPageScreen>
    with SingleTickerProviderStateMixin {

  //로컬에 있는 정보들을 담을 변수 : 좋아하는 곡들의 ID를 문자열로 담음
  List<String> favoriteAlbum = [];

  //로컬에 있는 정보를 가져오는 함수
  Future<void> getFavoriteAlbum() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final localData = prefs.getStringList('favorite_ids') ?? []; // null일 경우 빈 배열 반환

    setState(() {
      favoriteAlbum = localData;
    });
    print("[확인용]현재 로컬에 있는 데이터는 $favoriteAlbum");
  }

  //좋아요한 아이디를 비교해서 최종적으로 favoriteAlbum에 담고 저장하는 함수
  Future<void> toggleFavorite(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String strId = id.toString(); // ID를 문자열로 변환

    setState(() {
      if (favoriteAlbum.contains(strId)) {
        favoriteAlbum.remove(strId); // 이미 찜한 상태면 목록에서 제거
      } else {
        favoriteAlbum.add(strId); // 찜하지 않은 상태면 목록에 추가
      }
    });

    // 변경된 리스트를 기기에 다시 저장
    await prefs.setStringList('favorite_ids', favoriteAlbum);
  }

  bool _isAnimationOn = false; // 애니메이션 상태 변수

  // 트리거 변수 : 톤암의 초기 변수
  double _toneArmAngle = _armOut;

  static const double _armOut = 0.09; // 톤암의 최소 변수 (시작 위치)
  static const double _armLimit = 0.03; // 톤암의 최대 변수 (바이닐 접촉 위치)

  // 회전 애니메이션 컨트롤러
  late AnimationController _rotationController;

  // 페이지 컨트롤러 및 현재 추천 앨범 인덱스
  final controller = PageController(viewportFraction: 1.0, keepPage: true);
  int _currentRecommendPage = 0; // 현재 선택된 추천 바이닐의 인덱스

  // 추천 앨범 목록 (이미지 및 데이터)
  List<String> recommended = [];
  List<dynamic> top5Products = []; // 추천 바이닐의 전체 정보

  // 현재 바텀네비 인덱스
  int _currentIndex = 0;

  // 전체 상품 목록
  List<dynamic> product = [];

  // 선택된 정렬 옵션 (0: 인기 매물, 1: 최신 매물, 2: 가격 인하)
  int _selectedOptionIndex = 0;

  // 검색 컨트롤러
  final TextEditingController _ctrl = TextEditingController();

  String _token = ""; // 토큰 변수

  // 로컬 토큰 가져오기
  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? "토큰 없음";
  }

  // 정보들을 불러오는 함수
  Future<void> fetchData() async {
    final url = "https://connexChat-server.onrender.com/vinyl/products";
    await fetchToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $_token"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final parsedJson = jsonDecode(response.body);
        final List<dynamic> fetchedProducts = parsedJson['data'] ?? [];

        // 1. likeCount 내림차순 정렬용 사본 생성
        List<dynamic> sortedByLike = List.from(fetchedProducts);
        sortedByLike.sort(
              (a, b) => (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0),
        );

        // 2. 상위 5개 추출
        List<dynamic> top5 = sortedByLike.take(5).toList();
        List<String> top5Images = top5
            .map<String>((e) => e['albumImage'] as String? ?? '')
            .where((url) => url.isNotEmpty)
            .toList();

        setState(() {
          product = fetchedProducts;
          top5Products = top5;
          recommended = top5Images; // 추천 리스트에 5개 이미지 경로 할당
        });
      } else {
        print("통신 오류, 오류 코드 ${response.statusCode}");
      }
    } catch (e) {
      print("통신 실패 $e");
    }
  }

  // 선택 옵션 정렬 함수
  List<dynamic> getDisplayProducts() {
    List<dynamic> list = List.from(product);

    switch (_selectedOptionIndex) {
      case 0:
        list.sort(
              (a, b) => (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0),
        );
        break;
      case 1:
        list.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
        break;
      case 2:
        list.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
    }

    return list.take(10).toList();
  }

  //화면이 생성되면 시작될 부분
  @override
  void initState() {
    super.initState();

    //1. 애니메이션 관련

    // 3초에 1바퀴씩 무한 회전하는 애니메이션 컨트롤러 초기화
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // PageController 리스너를 통한 인디케이터/슬라이드 페이지 동기화
    controller.addListener(() {
      if (controller.page != null) {
        int next = controller.page!.round();
        if (_currentRecommendPage != next) {
          setState(() {
            _currentRecommendPage = next;
          });
        }
      }
    });

    fetchData();
    getFavoriteAlbum();
  }

  @override
  void dispose() {
    _rotationController.dispose(); // 컨트롤러 해제
    _ctrl.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = getDisplayProducts();

    // 현재 슬라이드 중인 추천 바이닐 객체
    final currentVinyl = (top5Products.isNotEmpty &&
        _currentRecommendPage < top5Products.length)
        ? top5Products[_currentRecommendPage]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: EasyAnimatedIndexedStack(
        index: _currentIndex,
        children: [
          // 1. 홈 화면
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // 로고 & 알림
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: Image.asset(
                          'assets/images/logo_vertical.png',
                          width: 100,
                          height: 50,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
                        },
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // 검색창
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "앨범명, 아티스트 검색",
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        prefixIcon: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.search,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("해당 기능은 준비중입니다.")),
                            );
                          },
                          icon: Icon(
                            Symbols.barcode_scanner,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 턴테이블 박스
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFDAA84D),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                child: Text(
                                  "오늘의추천 바이닐",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFDAA84D),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Text(
                            "오늘 이 바이닐은\n어떠세요?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 10),
                            child: Text(
                              '매일 새롭게 선별한 특별한 한 장',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),

                          // 턴테이블 및 앨범 이미지 PageView 영역
                          SizedBox(
                            width: 270,
                            height: 270,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // 1) 턴테이블 배경
                                Image.asset(
                                  'assets/images/turntable.png',
                                  width: 270,
                                  height: 270,
                                  fit: BoxFit.contain,
                                ),

                                // 2) 바이닐 레코드판
                                Positioned(
                                  top: 30,
                                  left: 30,
                                  child: RotationTransition(
                                    turns: _rotationController,
                                    child: Image.asset(
                                      'assets/images/vinyl.png',
                                      width: 200,
                                      height: 200,
                                    ),
                                  ),
                                ),

                                // 3) 추천 앨범 이미지 슬라이드 (PageView)
                                Positioned(
                                  top: 90,
                                  left: 92,
                                  child: RotationTransition(
                                    turns: _rotationController,
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: recommended.isEmpty
                                          ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFDAA84D),
                                        ),
                                      )
                                          : PageView.builder(
                                        controller: controller,
                                        itemCount: recommended.length,
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentRecommendPage = index;
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(100),
                                            child: Image.network(
                                              recommended[index],
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                // 4) 턴테이블 톤암
                                Positioned(
                                  top: -20,
                                  right: 0,
                                  child: Transform.rotate(
                                    angle: _toneArmAngle * 3.141592,
                                    alignment: const Alignment(0.7, -0.7),
                                    child: GestureDetector(
                                      onVerticalDragUpdate: (details) {
                                        setState(() {
                                          _toneArmAngle =
                                              (_toneArmAngle -
                                                  details.delta.dy * 0.0015)
                                                  .clamp(0.0, _armOut);
                                        });

                                        // 톤암 동작 시 상태 전환
                                        if (_toneArmAngle <= _armLimit) {
                                          if (!_rotationController
                                              .isAnimating) {
                                            _rotationController.repeat();
                                            setState(() {
                                              _isAnimationOn = true;
                                            });
                                          }
                                        } else {
                                          if (_rotationController.isAnimating) {
                                            _rotationController.stop();
                                            setState(() {
                                              _isAnimationOn = false;
                                            });
                                          }
                                        }
                                      },
                                      child: Image.asset(
                                        'assets/images/tonearm.png',
                                        width: 160,
                                        height: 160,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 5) 인디케이터
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SmoothPageIndicator(
                              controller: controller,
                              count: recommended.isEmpty
                                  ? 1
                                  : recommended.length,
                              effect: const ExpandingDotsEffect(
                                dotWidth: 8,
                                dotHeight: 8,
                                expansionFactor: 2.5,
                                spacing: 10,
                                activeDotColor: Color(0xFFDAA84D),
                                dotColor: Colors.grey,
                              ),
                              onDotClicked: (index) {
                                controller.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),

                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: _isAnimationOn
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,

                            firstChild: const SizedBox(
                              width: double.infinity,
                              height: 0,
                            ),

                            secondChild: GestureDetector(
                              onTap: () {
                                if (currentVinyl != null &&
                                    currentVinyl['id'] != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        id: currentVinyl['id'],
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin:
                                const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282828),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // 1) 현재 선택된 앨범 썸네일
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 46,
                                        height: 46,
                                        child: (recommended.isNotEmpty &&
                                            _currentRecommendPage <
                                                recommended.length)
                                            ? Image.network(
                                          recommended[
                                          _currentRecommendPage],
                                          fit: BoxFit.cover,
                                        )
                                            : Container(
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 2) 현재 선택된 앨범 및 아티스트 상세 정보
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentVinyl?['albumName'] ??
                                                'Blonde',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currentVinyl?['artist'] ??
                                                'Frank Ocean',
                                            style: const TextStyle(
                                              color: Color(0xFFDAA84D),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${currentVinyl?['genre'] ?? 'R&B/Soul'} · ${currentVinyl?['condition'] ?? 'M'}",
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3) 우측 이동 화살표
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 장르 타이틀
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Text(
                            '장르별 둘러보기',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '전체 보기',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.arrow_forward_ios_outlined,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 장르 카드 1열
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCard(
                        imgPath: "assets/icons/rock.svg",
                        text: "Rock",
                      ),
                      _buildCard(
                        imgPath: "assets/icons/jazz.svg",
                        text: "Jazz",
                      ),
                      _buildCard(imgPath: "assets/icons/pop.svg", text: "Pop"),
                      _buildCard(
                        imgPath: "assets/icons/hip-hop.svg",
                        text: "Hip-hop",
                      ),
                    ],
                  ),

                  // 장르 카드 2열
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCard(
                        imgPath: "assets/icons/electronic.svg",
                        text: "Electronic",
                      ),
                      _buildCard(
                        imgPath: "assets/icons/classical.svg",
                        text: "Classical",
                      ),
                      _buildCard(
                        imgPath: "assets/icons/rnb-soul.svg",
                        text: "R&B-Soul",
                      ),
                      _buildCard(imgPath: "assets/icons/etc.svg", text: "기타"),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 옵션 필터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildOption(text: "인기 매물", index: 0),
                      _buildOption(text: "최신 등록", index: 1),
                      _buildOption(text: "가격 인하", index: 2),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                '전체 보기',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios_outlined,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 상품 카드 (가로 스크롤)
                  product.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(),
                  )
                      : SizedBox(
                    height: 300, // [수정] 오버플로우를 막기 위해 높이를 300으로 넉넉하게 설정
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildProductCard(displayList[index]),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // 2. 검색
          const SearchScreen(),

          // 3. 더보기/진행
          const Center(
            child: Text(
              "현재 진행중인 부분",
              style: TextStyle(
                fontSize: 39,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 4. 관심상품
          WishlistScreen(key: ValueKey(_currentIndex)),

          // 5. 마이페이지
          const Center(
            child: Text(
              "마이페이지",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFF131313)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          onTap: (value) {
            setState(() {
              _currentIndex = value;
            });
            //탭을 이동할 때마다 좋아요 토글 버튼의 상태를 일치시키기 위해서 setState
            getFavoriteAlbum();
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: "검색",
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                backgroundColor: Color(0xFFDE9E4C),
                child: Icon(Icons.add, color: Colors.black),
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: "관심 상품",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
          ],
        ),
      ),
    );
  }

  // 상품 카드 렌더링
  Widget _buildProductCard(Map<String, dynamic> item) {
    // 1. 현재 상품이 찜 목록에 있는지 확인
    bool isFavorite = favoriteAlbum.contains(item['id'].toString());

    String formatPrice(dynamic price) {
      if (price == null) return '0';
      return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(id: item['id'])),
        ).then((_) {
          // 상세 화면에서 돌아왔을 때 찜 상태 갱신을 위해 데이터 재호출
          getFavoriteAlbum();
        });
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    item['albumImage'] ?? '',
                    width: double.infinity,
                    height: 170,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 170,
                      color: Colors.grey[800],
                      child: const Icon(Icons.album, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,

                    child: GestureDetector(
                      onTap: () {
                        // 누르면 처리할 로직 : 토글 함수 호출
                        toggleFavorite(item['id']);
                      },

                      child: CircleAvatar(
                          backgroundColor: const Color(0xFF131313),
                          child: Icon(
                            // 상태에 따라 아이콘 모양 및 색상 변경
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                          )
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['condition'] ?? 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['albumName'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['artist'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "₩ ${formatPrice(item['price'])}",
                    style: const TextStyle(
                      color: Color(0xFFDAA84D),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  Widget _buildCard({required String imgPath, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 85,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(imgPath, width: 32, height: 32),
                Text(
                  text,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({required String text, required int index}) {
    final bool isSelected = _selectedOptionIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_selectedOptionIndex != index) {
              setState(() {
                _selectedOptionIndex = index;
              });
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 2,
                color: isSelected ? Colors.orangeAccent : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}