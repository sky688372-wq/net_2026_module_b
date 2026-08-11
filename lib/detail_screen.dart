import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.id});

  final int id;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // 좋아요를 누른 상품 ID들을 관리하는 Set
  Set<String> _likedProductIds = {};

  // 저장된 좋아요 목록을 로드하는 함수
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentFavorites = prefs.getStringList('favorite_ids') ?? [];
    setState(() {
      _likedProductIds = currentFavorites.toSet();
    });
  }

  // 좋아요를 누른 곡(앨범)들을 저장/해제하는 함수
  Future<void> setFavorite(int id) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 기존 저장된 좋아요 ID 목록 가져오기 (없으면 빈 리스트)
    List<String> currentFavorites = prefs.getStringList('favorite_ids') ?? [];

    String idStr = id.toString();

    // 2. 이미 존재하는 경우 목록에서 제거(좋아요 취소), 없으면 추가(좋아요)
    if (currentFavorites.contains(idStr)) {
      currentFavorites.remove(idStr);
    } else {
      currentFavorites.add(idStr);
    }

    // 3. 변경된 목록을 로컬 SharedPreferences에 저장
    await prefs.setStringList('favorite_ids', currentFavorites);
    print("저장 완료");

    // 4. UI 갱신을 위해 내부 상태도 업데이트
    setState(() {
      _likedProductIds = currentFavorites.toSet();
    });
  }

  //영어를 한국어로 매핑해주는 함수
  String getTradeMethodText(String? method) {
    switch (method) {
      case 'DIRECT':
        return '직거래';
      case 'DELIVERY':
        return '택배거래';
      case 'BOTH':
        return '직거래/택배';
      default:
        return method ?? '';
    }
  }

  String? _token;
  Map<String, dynamic>? data;
  bool isLoading = true;

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? "토큰 없음";
  }

  Future<void> fetchDetailData() async {
    final url =
        "https://connexChat-server.onrender.com/vinyl/products/${widget.id}";

    await fetchToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $_token"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final parsedJson = jsonDecode(response.body);
        setState(() {
          data = parsedJson['data'];
          isLoading = false;
          print(data);
        });
        print(data);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // 저장된 좋아요 목록 가져오기
    fetchDetailData();
  }

  @override
  Widget build(BuildContext context) {
    // 기기의 상태바(Status Bar) 높이를 가져옴
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final bool isLiked = _likedProductIds.contains(widget.id.toString());

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(
        child: Text(
          "데이터를 불러올 수 없습니다.",
          style: TextStyle(color: Colors.white),
        ),
      )
          : Stack(
        children: [
          // 1. 전체 스크롤 영역 (이미지 + 태그 + 하단 내용)
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 이미지 영역
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Image.network(
                        data!['albumImage'] ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 380,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, color: Colors.white),
                      ),
                      Positioned(
                        top: statusBarHeight + 10,
                        right: 20,
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            onPressed: () {
                              setFavorite(widget.id);
                            },
                            icon: AnimatedSwitcher(
                              duration: Duration(seconds: 2),
                              switchInCurve: Curves.bounceIn,
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation, child: child,
                                );
                              },

                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 이미지 하단에 들어갈 상세 내용 영역
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // 앨범 명
                      Text(
                        data!['albumName'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 아티스트 명
                      Text(
                        data!['artist'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),

                      // 태그 영역 (장르, 상태, 거래방식)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: [
                          // 1. 장르 태그
                          if (data!['genre'] != null)
                            Chip(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              label: Text(
                                data!['genre'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: const Color(0xFF1E1E1E),
                              side: BorderSide.none,
                            ),

                          // 2. 상태(Condition) 태그
                          if (data!['condition'] != null)
                            Chip(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              label: Text(
                                data!['condition'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: const Color(0xFF1E1E1E),
                              side: BorderSide.none,
                            ),

                          // 3. API 기반 거래 방식(tradeMethod) 태그 추가
                          if (data!['tradeMethod'] != null)
                            Chip(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              label: Text(
                                getTradeMethodText(data!['tradeMethod']),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: const Color(0xFF1E1E1E),
                              side: BorderSide.none,
                            ),
                        ],
                      ),

                      //판매자 상세 정보 카드
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 1,
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF1E1E1E),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 16,
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFF554829,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      // 판매자 이름
                                      Text(
                                        data!['seller']['name'] ??
                                            '이름 없음',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // 판매자 이메일
                                      Text(
                                        data!['seller']['email'] ??
                                            '이메일 없음',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      //상태 등급 부분
                      Align(
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  '상태 등급',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Chip(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 0,
                                  ),
                                  visualDensity: const VisualDensity(
                                    horizontal: -4,
                                    vertical: -4,
                                  ),
                                  backgroundColor: Colors.black,
                                  side: BorderSide.none,
                                  label: Text(
                                    "${data!['condition']}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 2),

                            //상태 상세 정보
                            Text(
                              "${data!['conditionDescription']}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      //상품 설명
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            const Text(
                              "상품 설명",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "${data!['description']}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      //가격과 거래 방식 카드
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 14,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.start,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  //가격 부분
                                  Text(
                                    '가격',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    '\u20A9 ${NumberFormat('#,###').format(data!['price'] ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            //거래 방식 부분
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 14,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '거래 방식',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    getTradeMethodText(
                                      data!['tradeMethod'],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. 상단 고정 이전 버튼
          Positioned(
            top: statusBarHeight + 10,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("현재 해당 기능은 준비중인 기능입니다.")));
            },
            style: ElevatedButton.styleFrom(
              maximumSize: const Size(double.infinity, 60),
              backgroundColor: const Color(0xFFDFAC42),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text(
              '구매하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}