import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:net_2026/detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> product = []; // 찜한 상품 목록만 담을 리스트
  bool isLoading = true; // 로딩 상태 관리

  // 1. 저장된 좋아요 ID 목록을 불러오는 함수
  Future<List<String>> getFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteIds = prefs.getStringList('favorite_ids') ?? [];

    // 💡 디버깅 1: SharedPreferences에서 제대로 불러왔는지 확인
    print("================ DEBUG ================");
    print("1. 로컬(디바이스)에 저장된 좋아요 ID 목록: $favoriteIds");

    return favoriteIds;
  }

  // 2. 좋아요 해제 기능 (관심상품 목록에서 삭제용)
  Future<void> _removeFavorite(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentFavorites = prefs.getStringList('favorite_ids') ?? [];
    String idStr = id.toString();

    if (currentFavorites.contains(idStr)) {
      currentFavorites.remove(idStr);
      await prefs.setStringList('favorite_ids', currentFavorites);
      // 화면 목록에서 즉시 제거
      setState(() {
        product.removeWhere((item) => item['id'].toString() == idStr);
      });
    }
  }

  String _token = ""; // 토큰을 담을 변수

  // 로컬에 있는 토큰을 가져오는 함수
  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? "토큰 없음";
  }

  // 3. 데이터를 불러오고 저장된 ID와 비교하여 필터링하는 핵심 함수
  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    // 💡 핵심 수정: 기본 10~20개만 주는 서버라면 뒤에 있는 앨범을 못 가져오므로 size=100 추가
    final url = "https://connexChat-server.onrender.com/vinyl/products?size=100";
    await _fetchToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $_token"},
      );

      if (!mounted) return;

      // 💡 디버깅 2: 서버 연결 상태 확인
      print("2. 서버 응답 코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        // 한글 깨짐 방지를 위해 utf8.decode 사용
        final parsedJson = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> allProducts = parsedJson['data'] ?? [];

        // 💡 디버깅 3: 서버에서 가져온 전체 상품 개수와 실제 ID 확인
        print("3. 서버에서 불러온 전체 상품 개수: ${allProducts.length}");
        if (allProducts.isNotEmpty) {
          List<String> serverProductIds = allProducts.map((e) => e['id'].toString()).toList();
          print("4. 서버에서 넘어온 상품들의 ID 리스트: $serverProductIds");
        }

        // [핵심] 로컬에 저장된 ID 목록 가져오기
        final List<String> favoriteIds = await getFavorite();

        // [핵심] 전체 상품 중 저장된 ID를 포함하는 상품만 필터링
        final List<dynamic> likedProducts = allProducts.where((item) {
          // item['id']가 int로 들어오더라도 강제로 String으로 변환 후 비교
          return favoriteIds.contains(item['id'].toString());
        }).toList();

        // 💡 디버깅 4: 최종 필터링된 결과물 개수 확인
        print("5. 최종적으로 화면에 그릴 찜 상품 개수: ${likedProducts.length}");
        print("=======================================");

        setState(() {
          product = likedProducts; // 필터링된 리스트로 갱신
          isLoading = false;
        });
      } else {
        print("통신 오류, 오류 코드 ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("통신 실패 또는 JSON 파싱 에러: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 가격 천 단위 쉼표 포맷팅 함수
  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // 거래 방식 매핑 함수
  String _formatTradeMethod(dynamic method) {
    switch (method) {
      case 'DIRECT':
        return '직거래';
      case 'DELIVERY':
        return '택배 거래';
      case 'BOTH':
        return '직거래/택배';
      default:
        return '판매자와 협의';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 1. 상단 타이틀
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: const Text(
                    "관심 상품",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: IconButton(
                      onPressed: () {
                        //누르면 새로 고침 로직 : 원래 화면으로 이동 시 되는게 맞는데 IndexedStack이라 initState가 작동을 안하므로 타협봄
                        fetchData();
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white.withValues(alpha: 0.7),
                      )
                  ),
                )
              ],
            ),
          ),

          // 2. 관심 상품 목록 영역
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFDAA84D)),
            )
                : product.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
              onRefresh: fetchData, // 당겨서 새로고침 지원
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: product.length,
                itemBuilder: (context, index) {
                  final item = product[index];

                  return GestureDetector(
                    onTap: () async {
                      // 상세화면으로 이동 후 돌아왔을 때 좋아요 상태 반영을 위해 fetchData 실행
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailScreen(id: item['id']),
                        ),
                      );
                      fetchData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 앨범 이미지
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 12),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey[800],
                              ),
                              child: Image.network(
                                item['albumImage'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                const Icon(
                                  Icons.album,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),

                            // 상세 정보 및 삭제 버튼
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // 앨범명, 아티스트, 상태
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['albumName'] ?? '',
                                              overflow:
                                              TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['artist'] ?? '',
                                              overflow:
                                              TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withValues(
                                                  alpha: 0.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                  8,
                                                ),
                                                color: Colors.black,
                                              ),
                                              padding:
                                              const EdgeInsets.symmetric(
                                                vertical: 4,
                                                horizontal: 8,
                                              ),
                                              child: Text(
                                                item['condition'] ?? 'M',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                item['genre'] ?? 'ETC',
                                                overflow:
                                                TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white
                                                      .withValues(
                                                    alpha: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // 가격 및 하트 삭제 버튼
                                  Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      // 찜 삭제(하트) 버튼
                                      GestureDetector(
                                        onTap: () {
                                          _removeFavorite(item['id']);
                                        },
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),

                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "₩${_formatPrice(item['price'])}",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xffc8b46c),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatTradeMethod(
                                              item['tradeMethod'],
                                            ),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 관심 상품이 없을 때 표시할 위젯
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 90,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            '관심 상품이 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "마음에 드는 상품에 하트를 눌러보세요.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}