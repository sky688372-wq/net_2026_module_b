import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ==========================================
// 1. 모델 클래스 정의
// ==========================================

// 유저 모델 클래스
class UserInfo {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final List<int> likedAlbumIds; // 좋아요를 누른 앨범 ID 목록 저장

  UserInfo({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.likedAlbumIds = const [],
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      likedAlbumIds: json['likedAlbumIds'] != null
          ? List<int>.from(json['likedAlbumIds'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'likedAlbumIds': likedAlbumIds,
    };
  }

  // 좋아요 목록 업데이트용 copyWith
  UserInfo copyWith({
    int? id,
    String? email,
    String? name,
    String? phone,
    List<int>? likedAlbumIds,
  }) {
    return UserInfo(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      likedAlbumIds: likedAlbumIds ?? this.likedAlbumIds,
    );
  }
}

// 판매자 모델 클래스
class Seller {
  final int id;
  final String name;
  final String email;
  final String? profileImage;

  Seller({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
    };
  }
}

// 앨범 모델 클래스
class AlbumModel {
  final int id;
  final String albumName;
  final String artist;
  final String genre;
  final String condition;
  final String? conditionDescription;
  final int price;
  final String tradeMethod;
  final String? description;
  final String albumImage;
  final Seller? seller;
  final int likeCount;
  final String createdAt;

  AlbumModel({
    required this.id,
    required this.albumName,
    required this.artist,
    required this.genre,
    required this.condition,
    this.conditionDescription,
    required this.price,
    required this.tradeMethod,
    this.description,
    required this.albumImage,
    this.seller,
    required this.likeCount,
    required this.createdAt,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] ?? 0,
      albumName: json['albumName'] ?? '',
      artist: json['artist'] ?? '',
      genre: json['genre'] ?? 'ETC',
      condition: json['condition'] ?? 'M',
      conditionDescription: json['conditionDescription'],
      price: json['price'] ?? 0,
      tradeMethod: json['tradeMethod'] ?? 'DIRECT',
      description: json['description'],
      albumImage: json['albumImage'] ?? '',
      seller: json['seller'] != null ? Seller.fromJson(json['seller']) : null,
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumName': albumName,
      'artist': artist,
      'genre': genre,
      'condition': condition,
      'conditionDescription': conditionDescription,
      'price': price,
      'tradeMethod': tradeMethod,
      'description': description,
      'albumImage': albumImage,
      'seller': seller?.toJson(),
      'likeCount': likeCount,
      'createdAt': createdAt,
    };
  }
}

// ==========================================
// 2. 앱 전역 유저 상태 관리 클래스 (UserProvider)
// ==========================================
class UserProvider extends ChangeNotifier {
  UserInfo _currentUser = UserInfo(
    id: 1,
    email: '',
    name: '',
    likedAlbumIds: [],
  );

  UserInfo get currentUser => _currentUser;

  // 유저 데이터 수동 주입
  void setUser(UserInfo user) {
    _currentUser = user;
    notifyListeners();
  }

  // 좋아요 토글
  void toggleLike(int albumId) {
    List<int> updatedLikes = List.from(_currentUser.likedAlbumIds);
    if (updatedLikes.contains(albumId)) {
      updatedLikes.remove(albumId);
    } else {
      updatedLikes.add(albumId);
    }
    _currentUser = _currentUser.copyWith(likedAlbumIds: updatedLikes);
    notifyListeners();
  }

  // 좋아요 여부 판단
  bool isLiked(int albumId) {
    return _currentUser.likedAlbumIds.contains(albumId);
  }
}

// ==========================================
// 3. UI 화면 (WishlistScreen)
// ==========================================
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Map/dynamic 대신 AlbumModel 리스트 사용
  List<AlbumModel> product = [];

  String _token = "";

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? "토큰 없음";
  }

  Future<void> fetchData() async {
    final url = "https://connexChat-server.onrender.com/vinyl/products";
    await _fetchToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $_token"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final parsedJson = jsonDecode(response.body);
        final List<dynamic> dataList = parsedJson['data'] ?? [];

        setState(() {
          // JSON 배열을 AlbumModel 리스트로 형변환 및 생성
          product = dataList.map((e) => AlbumModel.fromJson(e)).toList();
        });
      } else {
        print("통신 오류, 오류 코드 ${response.statusCode}");
      }
    } catch (e) {
      print("통신 실패 $e");
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatTradeMethod(String method) {
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
      body: product.isEmpty
          ? _buildLoading()
          : Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
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
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: product.length,
              itemBuilder: (context, index) {
                final item = product[index]; // AlbumModel 객체
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. 이미지
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
                            item.albumImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.album,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),

                        // 2. 우측 콘텐츠
                        Expanded(
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                          item.albumName,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.artist,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            color: Colors.black,
                                          ),
                                          padding:
                                          const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            item.condition,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            item.genre,
                                            overflow:
                                            TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "₩${_formatPrice(item.price)}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xffc8b46c),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTradeMethod(item.tradeMethod),
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
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
        ),
      ],
    );
  }
}