import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {

  //토큰, 유저 id를 불러오는 함수 : 토큰이 존재함을 확인함 -> 고로 애는 범인이 아님
  var _token;
  var _userId;

  Future<void> _fetchToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('token') ?? '';
    _userId  = prefs.getInt('userId') ?? 0;
  }


  //상품을 등록할 수 있도록 해주는 함수
  Future<void> submitProduct() async {
    final url = "https://connexChat-server.onrender.com/vinyl/products";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        }
      );

      if(response.statusCode == 200) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 등록 성공'))
        );
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('상품 등록 실패 ${response.statusCode}'))
        );
      }
    } catch(e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 등록 싶패 $e'))
      );
    }
  }



  // 컨트롤러
  final TextEditingController albumNameCtrl = TextEditingController();
  final TextEditingController albumArtistCtrl = TextEditingController();
  final TextEditingController albumPriceCtrl = TextEditingController();
  final TextEditingController albumBarcodeCtrl = TextEditingController();
  final TextEditingController albumDescriptionCtrl = TextEditingController();
  final TextEditingController barCodeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();



  // 컨트롤러 메모리 해제
  @override
  void dispose() {
    albumNameCtrl.dispose();
    albumArtistCtrl.dispose();
    albumPriceCtrl.dispose();
    albumBarcodeCtrl.dispose();
    albumDescriptionCtrl.dispose();
    super.dispose();
  }

  // 장르를 담을 리스트
  final List<String> genreList = [
    'ROCK',
    'JAZZ',
    'POP',
    'HIPHOP',
    'ELECTRONIC',
    'CLASSICAL',
    'RNB_SOUL',
    'ETC',
  ];

  // 장르 선택 확인 트리거
  List<bool> genreState = List.generate(8, (_) => false);

  // 장르 선택 시 나머지를 false로 바꾸는 함수
  void selectGenre(int index) {
    setState(() {
      for (int i = 0; i < genreState.length; i++) {
        genreState[i] = (i == index);
      }
    });
  }

  // 선택한 음반의 설명
  String? selectFullName;
  String? selectDescription;

  // 1. 음반 상태 리스트
  final List<Map<String, String>> conditionInfoList = [
    {
      'code': 'SS',
      'fullName': 'Still Sealed',
      'description': '미개봉 새상품. 완벽한 상태입니다.',
    },
    {
      'code': 'M',
      'fullName': 'Mint',
      'description': '개봉했으나 새것과 다름없는 완벽한 상태입니다.',
    },
    {
      'code': 'NM',
      'fullName': 'Near Mint',
      'description': '거의 새것에 가까운 상태로, 미세한 사용감만 있습니다.',
    },
    {
      'code': 'EX',
      'fullName': 'Excellent',
      'description': '전체적으로 깨끗하며, 약간의 사용감이 있습니다.',
    },
    {
      'code': 'VG+',
      'fullName': 'Very Good Plus',
      'description': '양호한 상태로, 재생에 문제가 없습니다.',
    },
    {
      'code': 'VG',
      'fullName': 'Very Good',
      'description': '사용감이 있으나 재생에 큰 문제가 없습니다.',
    },
    {'code': 'G', 'fullName': 'Good', 'description': '사용감이 많으나 재생은 가능합니다.'},
  ];

  // 2. 음반 상태 선택 트리거 리스트
  List<bool> conditionState = List.generate(7, (_) => false);

  // 3. 음반 상태 선택 함수
  void selectCondition(int index) {
    setState(() {
      for (int i = 0; i < conditionState.length; i++) {
        conditionState[i] = (i == index);
      }
      selectFullName = conditionInfoList[index]['fullName'];
      selectDescription = conditionInfoList[index]['description'];
    });
  }

  // 거래 방식 리스트 및 선택 상태
  final List<String> tradeTypeList = ["직거래", "택배", "둘 다 가능"];
  List<bool> tradeTypeState = List.generate(3, (_) => false);

  void selectTradeType(int index) {
    setState(() {
      for (int i = 0; i < tradeTypeState.length; i++) {
        tradeTypeState[i] = (i == index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131313),
        title: const Text(
          '상품 등록',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 앨범명
              const Text(
                '앨범명 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildNormalTextField(
                hintText: "앨범명을 입력하세요",
                controller: albumNameCtrl,
              ),

              // 2. 아티스트
              const Text(
                '아티스트 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildNormalTextField(
                controller: albumArtistCtrl,
                hintText: "아티스트 명을 입력해주세요.",
              ),

              const SizedBox(height: 10),

              // 3. 장르
              const Text(
                '장르 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(genreList.length, (index) {
                  final currentGenre = genreList[index];
                  final isSelected = genreState[index];

                  return GestureDetector(
                    onTap: () => selectGenre(index),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSelected ? 1.0 : 0.5,
                      child: Chip(
                        padding: const EdgeInsets.all(1.5),
                        backgroundColor: isSelected
                            ? Colors.amber
                            : const Color(0xFF191A1C),
                        label: Text(
                          currentGenre,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // 4. 음반 상태
              const Text(
                '음반 상태 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(conditionInfoList.length, (index) {
                  final currentCondition = conditionInfoList[index];
                  final isSelected = conditionState[index];

                  return GestureDetector(
                    onTap: () => selectCondition(index),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSelected ? 1.0 : 0.5,
                      child: Chip(
                        padding: const EdgeInsets.all(1.5),
                        backgroundColor: isSelected
                            ? Colors.amber
                            : const Color(0xFF191A1C),
                        label: Text(
                          currentCondition['code']!,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),

              // 선택한 상태 안내 문구
              if (selectFullName != null)
                Text(
                  '$selectFullName - $selectDescription',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),

              const SizedBox(height: 20),

              // 5. 가격
              const Text(
                '가격 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildNormalTextField(
                hintText: "가격을 입력하세요",
                controller: albumPriceCtrl,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10),

              // 6. 거래 방식 (Wrap을 사용하여 올바르게 렌더링)
              const Text(
                '거래 방식 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(tradeTypeList.length, (index) {
                  final item = tradeTypeList[index];
                  final isSelected = tradeTypeState[index];

                  return GestureDetector(
                    onTap: () => selectTradeType(index),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSelected ? 1.0 : 0.5,
                      child: Chip(
                        padding: const EdgeInsets.all(1.5),
                        backgroundColor: isSelected
                            ? Colors.amber
                            : const Color(0xFF191A1C),
                        label: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),

              //바코드 번호 입력 부분
              const Text(
                '바코드 번호 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              _buildNormalTextField(
                  controller: barCodeController,
                  hintText: "바코드 번호(선택)"
              ),

              //상품 설명
              const Text(
                '상품 설명 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              //이 부분의 텍스트 필드는 크기가 크고 순차적으로 입력되도록 하고 있음
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextField(
                  controller: descriptionController,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "상품에 대한 상세 설명을 입력하세요",
                    hintStyle: const TextStyle(color: Colors.white38),

                    // 1. 기본 테두리
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),

                    // 2. 평소(포커스 x) 상태 테두리
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),

                    // 3. 터치/입력 중(포커스 o) 상태 테두리
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        width: 1.5,          // 포커스 시 테두리 두께를 약간 두껍게 설정 가능
                      ),
                    ),

                    // 4. 에러 발생 시 테두리 (선택 사항)
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Color(0xFFDAA84D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(8)
                    )
                  ),

                    onPressed: () {
                      //누르면 REst API로 상품 등록을 처리할 로직
                      //태그 : 상품 삭제 처리 로직
                      submitProduct();
                    },
                    child: Text(
                      '등록하기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
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

  Widget _buildNormalTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.amber),
          ),
        ),
      ),
    );
  }
}