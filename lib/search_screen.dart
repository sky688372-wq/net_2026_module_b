import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:net_2026/detail_screen.dart';
import 'package:net_2026/module_b/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// main.dart에 정의된 routeObserver를 사용하기 위해 임포트
import 'package:net_2026/main.dart';

// API 반환 데이터 모델
class AlbumModel {
  final int id;
  final String title;
  final String artist;
  final int price;
  final String condition;
  final String genre;
  final String tradeMethod;
  final String imageUrl;

  AlbumModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.price,
    required this.condition,
    required this.genre,
    required this.tradeMethod,
    required this.imageUrl,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] ?? 0,
      title: json['albumName'] ?? '',
      artist: json['artist'] ?? '',
      price: json['price'] ?? 0,
      condition: json['condition'] ?? '',
      genre: json['genre'] ?? '',
      tradeMethod: json['tradeMethod'] ?? '',
      imageUrl: json['albumImage'] ?? '',
    );
  }
}

class SearchScreen extends StatefulWidget {
  final int tabIndex;

  const SearchScreen({super.key, this.tabIndex = 0});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

// 1. RouteAware 믹스인 추가: 화면 전환(Back 버튼 등) 감지를 위함
class _SearchScreenState extends State<SearchScreen> with RouteAware {
  //좋아요 동기화처리 완료

  final String baseUrl = "https://connexChat-server.onrender.com/vinyl/products";

  final TextEditingController _ctrl = TextEditingController();
  bool isExpanded = true;
  bool isLoading = false;

  // API 결과 목록 및 총 개수
  List<AlbumModel> _filteredList = [];
  int _totalCount = 0;

  // 로컬 좋아요 데이터 관리를 위한 변수 및 함수
  List<String> favoriteAlbum = [];

  Future<void> getFavoriteAlbum() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final localData = prefs.getStringList('favorite_ids') ?? [];
    if (mounted) {
      setState(() {
        favoriteAlbum = localData;
      });
      debugPrint("SearchScreen: Local Favorites Synced -> $favoriteAlbum");
    }
  }

  Future<void> toggleFavorite(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String strId = id.toString();

    setState(() {
      if (favoriteAlbum.contains(strId)) {
        favoriteAlbum.remove(strId);
      } else {
        favoriteAlbum.add(strId);
      }
    });

    await prefs.setStringList('favorite_ids', favoriteAlbum);
  }

  // 장르 데이터 및 매핑
  final List<String> genreList = [
    '전체', 'Rock', 'Jazz', 'Pop', 'Hip-Hop', 'Electronic', 'Classical', 'RnB/Soul', 'Etc'
  ];
  final Map<String, String> genreApiMap = {
    '전체': '',
    'Rock': 'ROCK',
    'Jazz': 'JAZZ',
    'Pop': 'POP',
    'Hip-Hop': 'HIPHOP',
    'Electronic': 'ELECTRONIC',
    'Classical': 'CLASSICAL',
    'RnB/Soul': 'RNB_SOUL',
    'Etc': 'ETC',
  };
  List<bool> genreState = List.generate(9, (i) => i == 0);

  // 음반 상태 데이터 및 매핑
  final List<String> albums = ['전체', 'Mint', 'NM', 'VG+', 'VG', 'G'];
  final Map<String, String> conditionApiMap = {
    '전체': '', 'Mint': 'M', 'NM': 'NM', 'VG+': 'VG+', 'VG': 'VG', 'G': 'G'
  };
  List<bool> albumConditions = List.generate(6, (i) => i == 0);

  // 가격 범위
  RangeValues _priceRange = const RangeValues(1000, 1000000);

  // 거래 방식 데이터 및 매핑
  final List<String> tradeMethods = ['전체', '직거래', '택배', '둘 다'];
  final Map<String, String> tradeApiMap = {
    '전체': '', '직거래': 'DIRECT', '택배': 'DELIVERY', '둘 다': 'BOTH'
  };
  List<bool> tradeState = List.generate(4, (i) => i == 0);

  // 정렬 옵션 및 매핑
  String _selectedSort = '최신 등록순';
  final List<String> _sortOptions = ['최신 등록순', '낮은 가격순', '인기순'];
  final Map<String, String> sortApiMap = {
    '최신 등록순': 'recent',
    '낮은 가격순': 'price_asc',
    '인기순': 'popular'
  };

  @override
  void initState() {
    super.initState();
    getFavoriteAlbum();
    fetchProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 2. RouteObserver에 현재 화면 등록
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // 3. RouteObserver 등록 해제 (메모리 누수 방지)
    routeObserver.unsubscribe(this);
    _ctrl.dispose();
    super.dispose();
  }

  // 4. 다른 화면에서 이 화면으로 돌아올 때 호출 (Navigator.pop 등)
  @override
  void didPopNext() {
    debugPrint("SearchScreen: didPopNext triggered. Refreshing favorites.");
    getFavoriteAlbum();
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 5. 탭 전환 감지 (IndexedStack 환경)
    if (oldWidget.tabIndex != widget.tabIndex) {
      // 탭이 Search(1)로 변경되었을 때 로컬 데이터 최신화
      if (widget.tabIndex == 1) {
        getFavoriteAlbum();
      }
      // 탭 변경 시 데이터 재요청 (검색 조건 유지 목적 등)
      fetchProducts();
    } else {
      // 상위 위젯(MainPage)의 일반적인 리빌드 시에도 상태 동기화 유지
      getFavoriteAlbum();
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // API 통신 및 검색 처리 함수
  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _getToken();

      String genreKey = genreList[genreState.indexOf(true)];
      String conditionKey = albums[albumConditions.indexOf(true)];
      String tradeKey = tradeMethods[tradeState.indexOf(true)];

      Map<String, String> queryParams = {
        'sort': sortApiMap[_selectedSort] ?? 'recent',
        'page': '1',
        'size': '50',
      };

      if (_ctrl.text.trim().isNotEmpty) {
        queryParams['keyword'] = _ctrl.text.trim();
      }
      if (genreApiMap[genreKey]!.isNotEmpty) {
        queryParams['genres'] = genreApiMap[genreKey]!;
      }
      if (conditionApiMap[conditionKey]!.isNotEmpty) {
        queryParams['conditions'] = conditionApiMap[conditionKey]!;
      }
      if (tradeApiMap[tradeKey]!.isNotEmpty && tradeKey != '둘 다') {
        queryParams['tradeMethod'] = tradeApiMap[tradeKey]!;
      }
      queryParams['minPrice'] = _priceRange.start.toInt().toString();
      queryParams['maxPrice'] = _priceRange.end.toInt().toString();

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded['success'] == true) {
          final List<dynamic> dataList = decoded['data'] ?? [];
          setState(() {
            _filteredList = dataList.map((e) => AlbumModel.fromJson(e)).toList();
            _totalCount = decoded['pagination']?['totalCount'] ?? decoded['totalCount'] ?? _filteredList.length;
          });
        }
      }
    } on TimeoutException {
      debugPrint("서버 응답 시간 초과 (Onrender 서버 대기 중일 수 있음)");
    } catch (e) {
      debugPrint("API 연동 에러 발생: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void genreStateUpdate(int selectedIndex) {
    setState(() {
      for (int i = 0; i < genreState.length; i++) {
        genreState[i] = (i == selectedIndex);
      }
    });
    fetchProducts();
  }

  void albumConditionsUpdate(int selectedIndex) {
    setState(() {
      for (int i = 0; i < albumConditions.length; i++) {
        albumConditions[i] = (i == selectedIndex);
      }
    });
    fetchProducts();
  }

  void tradeStateUpdate(int selectedIndex) {
    setState(() {
      for (int i = 0; i < tradeState.length; i++) {
        tradeState[i] = (i == selectedIndex);
      }
    });
    fetchProducts();
  }

  void resetFilters() {
    setState(() {
      genreState = List.generate(genreState.length, (i) => i == 0);
      albumConditions = List.generate(albumConditions.length, (i) => i == 0);
      tradeState = List.generate(tradeState.length, (i) => i == 0);
      _priceRange = const RangeValues(1000, 1000000);
      _ctrl.clear();
    });
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Image.asset(
                      'assets/images/logo_vertical.png',
                      width: 100,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) =>
                      const Text("LOGO", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // 6. 알림 화면 이동 후 돌아올 때 동기화 (.then 추가)
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()))
                          .then((_) => getFavoriteAlbum());
                    },
                    icon: const Icon(Icons.notifications, color: Colors.white),
                  ),
                ],
              ),

              // 검색 입력창
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (val) => fetchProducts(),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "앨범명, 아티스트 검색",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    prefixIcon: IconButton(
                      onPressed: () => fetchProducts(),
                      icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("현재 해당 기능은 준비중입니다."))
                        );
                      },
                      icon: Icon(Symbols.barcode_scanner, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 필터 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_sharp, color: Colors.white.withValues(alpha: 0.6)),
                        const SizedBox(width: 5),
                        const Text("필터", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    GestureDetector(
                      onTap: resetFilters,
                      child: const Text("필터 초기화", style: TextStyle(fontSize: 13, color: Color(0xFFDAA84D), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // 접기/펼치기 필터 옵션
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                  children: [
                    _buildFilterRow("장르", genreList, genreState, genreStateUpdate),
                    _buildFilterRow("음반 상태", albums, albumConditions, albumConditionsUpdate),

                    // 가격 범위 슬라이더
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text("가격 범위", style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Row(
                                children: [
                                  _priceBox("₩${_priceRange.start.toInt().toString().replaceAllRegExp(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}"),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 4,
                                        activeTrackColor: const Color(0xFFDAA84D),
                                        inactiveTrackColor: const Color(0xFF1E1E1E),
                                        thumbColor: const Color(0xFFDAA84D),
                                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                                      ),
                                      child: RangeSlider(
                                        values: _priceRange,
                                        min: 1000,
                                        max: 1000000,
                                        onChangeEnd: (values) => fetchProducts(),
                                        onChanged: (RangeValues values) {
                                          setState(() {
                                            double safeStart = values.start.clamp(1000.0, 1000000.0);
                                            double safeEnd = values.end.clamp(1000.0, 1000000.0);

                                            if (safeStart > safeEnd) {
                                              safeStart = safeEnd;
                                            }

                                            _priceRange = RangeValues(safeStart, safeEnd);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  _priceBox(_priceRange.end >= 1000000 ? "₩1,000,000+" : "₩${_priceRange.end.toInt().toString().replaceAllRegExp(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildFilterRow("거래 방식", tradeMethods, tradeState, tradeStateUpdate),
                  ],
                )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 10),

              // 접기 토글 버튼
              GestureDetector(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isExpanded ? "접기" : "펼치기", style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(width: 4),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.7), size: 18),
                    ],
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 0.7,
                      )
                    ]
                ),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.04),
                  height: 10,
                ),
              ),

              const SizedBox(height: 15),

              // 검색 결과 개수 및 정렬
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("검색 결과 $_totalCount개", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedSort,
                      dropdownColor: const Color(0xFF252525),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      items: _sortOptions.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedSort = newValue);
                          fetchProducts();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // 결과 그리드뷰
              isLoading
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: CircularProgressIndicator(color: Color(0xFFDAA84D)))
                  : _filteredList.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Text("조건에 부합하는 음반이 없습니다.", style: TextStyle(color: Colors.white54, fontSize: 14)))
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _filteredList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final album = _filteredList[index];
                  bool isFavorite = favoriteAlbum.contains(album.id.toString());

                  return GestureDetector(
                    onTap: () {
                      // 7. 상세 화면 이동 후 돌아올 때 동기화 (.then 추가)
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DetailScreen(id: album.id)),
                      ).then((_) {
                        getFavoriteAlbum();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1.0,
                                child: Image.network(
                                  album.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800]),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                                  child: Text(album.condition, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () {
                                    toggleFavorite(album.id);
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: const Color(0xFF131313).withValues(alpha: 0.6),
                                    radius: 14,
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 6),
                                Text("₩ ${album.price.toString().replaceAllRegExp(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}", style: const TextStyle(color: Color(0xFFDAA84D), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(String label, List<String> list, List<bool> states, Function(int) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final isSelected = states[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFDAA84D) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            list[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
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

  Widget _priceBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }
}

extension StringFormatter on String {
  String replaceAllRegExp(RegExp regex, String replacement) {
    return replaceAllMapped(regex, (match) => replacement);
  }
}
