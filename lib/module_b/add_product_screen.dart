import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:net_2026/detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  String? email;
  String? password;
  int? userId;

//유저의 id, 이메일, 비밀번호를 가져오는 함수
  Future<void> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    password = prefs.getString('password');
    userId = prefs.getInt('userId');

    print(email);
    print(password);
    print(userId);
  }


  // 데이터를 담을 리스트
  List<dynamic> productList = [];

  // 로컬에 있는 토큰을 불러오는 변수
  String? token;

  // 천 단위 콤마 포맷 함수 (예: 95000 -> 95,000)
  String formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // 로컬에 있는 이메일과 이이디 + 토큰 불러오기 함수
  Future<void> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  // 서버 데이터 조회 함수
  Future<void> getData() async {
    await getToken();

    final url = "https://connexChat-server.onrender.com/vinyl/products/me";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        // print(decodedData);
        // print(decodedData.runtimeType);

        setState(() {
          if (decodedData['data'] != null &&
              decodedData['data']['products'] is List) {
            productList = decodedData['data']['products'];
          }
        });
      } else {
        print("통신 오류, 오류 코드 : ${response.statusCode}");
      }
    } catch (e) {
      print("통신 실패 $e");
    }
  }

  //데이터를 지우는 함수
  // [수정] albumId와 리스트 인덱스(index)를 같이 넘겨받음
  Future<void> deleteData(int albumId, int index) async {
    await getToken(); // [수정] 토큰 불러오기 추가

    final url = "https://connexChat-server.onrender.com/vinyl/products/$albumId";

    try {
      final response = await http.delete(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $token", // [수정] userId 대신 Authorization Bearer 토큰 전달
          }
      );

      if(response.statusCode == 200) {
        print("삭제 성공");
        //예 버튼 클릭 시 리스트에서 없애고 화면을 다시 그린다.
        setState(() {
          productList.removeAt(index); // [수정] albumId 대신 화면 리스트 순서(index)로 지움
        });
      } else {
        print("삭제 오류 , 오류 코드 #${response.statusCode}");
      }
    }catch(e) {
      print("삭제 실패 $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),

      // 1. 앱바
      appBar: AppBar(
        backgroundColor: const Color(0xFF131313),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              //+ 버튼을 누르면 상품 등록 화면으로 넘어가도록 해야함
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("현재 진행중인 기능입니다.")));
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
        title: const Text(
          '내 등록 상품',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // 2. 메인 콘텐츠
      body: ListView.builder(
        itemCount: productList.length,
        itemBuilder: (context, index) {
          final item = productList[index];

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(id: item['id'])));
              },

              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF1E1E1E),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 앨범 이미지
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        item['albumImage'] ?? '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // 텍스트 정보 영역
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['albumName'] ?? '이름 없음',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['artist'] ?? '아티스트 미상',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // 상태 뱃지
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item['condition'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 가격
                              Text(
                                '₩ ${formatPrice(item['price'] ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 우측 아이콘 영역
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white54,
                            size: 22,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("현재 해당 기능은 준비중입니다.")),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          onPressed: () {
                            //휴지통 아이콘 누를 시 이벤트 처리
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Color(0xFF1E1E1E),
                                  title: Text(
                                    '${item['albumName']}을 삭제하시겠습니까?',
                                    style: TextStyle(color: Colors.white, fontSize: 20),
                                  ),
                                  //예, 아니오 버튼
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "아니오",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        deleteData(item['id'], index);
                                      },
                                      child: Text(
                                        "예",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}