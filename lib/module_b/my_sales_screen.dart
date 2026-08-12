import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {
  //컨트롤러
  TextEditingController albumNameCtrl = TextEditingController();
  TextEditingController albumArtistCtrl = TextEditingController();
  TextEditingController albumPriceCtrl = TextEditingController();
  TextEditingController albumBarcodeCtrl = TextEditingController();
  TextEditingController albumDescriptionCtrl = TextEditingController();

  //장르를 담을 리스트
  List<String> genreList = [
    'ROCK',
    'JAZZ',
    'POP',
    'HIPHOP',
    'ELECTRONIC',
    'CLASSICAL',
    'RNB_SOUL',
    'ETC',
  ];

  //장르 선택 확인 트리거
  List<bool> genreState = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  //장르 선택 시 나머지를 false로 바꾸는 함수
  void selectGenre(int index) {
    setState(() {
      for (int i = 0; i < genreState.length; i++) {
        genreState[i] = (i == index);
      }
    });
  }

  //이 아래부터 음반 상태 관련


// 1. 음반 상태 리스트 (화면 표시용)
  List<Map<String, String>> conditionInfoList = [
    {
      'code': 'SS',
      'fullName': 'Still Sealed',
      'description': '미개봉 새상품. 완벽한 상태입니다.',
    },
    {
      'code': 'M',
      'fullName': 'Mint',
      'description': 'Mint. 개봉했으나 새것과 다름없는 완벽한 상태입니다.',
    },
    {
      'code': 'NM',
      'fullName': 'Near Mint',
      'description': 'Near Mint. 거의 새것에 가까운 상태로, 미세한 사용감만 있습니다.',
    },
    {
      'code': 'EX',
      'fullName': 'Excellent',
      'description': 'Excellent. 전체적으로 깨끗하며, 약간의 사용감이 있습니다.',
    },
    {
      'code': 'VG+',
      'fullName': 'Very Good Plus',
      'description': 'Very Good Plus. 양호한 상태로, 재생에 문제가 없습니다.',
    },
    {
      'code': 'VG',
      'fullName': 'Very Good',
      'description': 'Very Good. 사용감이 있으나 재생에 큰 문제가 없습니다.',
    },
    {
      'code': 'G',
      'fullName': 'Good',
      'description': 'Good. 사용감이 많으나 재생은 가능합니다.',
    },
  ];


// 2. 음반 상태 선택 확인 트리거 리스트
  List<bool> conditionState = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

// 3. 음반 상태 선택 함수 (하나만 true로 변경)
  void selectCondition(int index) {
    setState(() {
      for (int i = 0; i < conditionState.length; i++) {
        conditionState[i] = (i == index);
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

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            //1. 앨범 입력 부분
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

            //2. 아티스트 입력 부분
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


            //3. 장르 칩 부분들
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
              spacing: 8.0, // 가로 간격
              runSpacing: 8.0, // 세로 줄바꿈 간격
              children: List.generate(genreList.length, (index) {
                final currentGenre = genreList[index];

                return GestureDetector(
                  onTap: () {
                    selectGenre(index);
                  },
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: genreState[index] ? 1.0 : 0.5,

                    child: Chip(
                      padding: EdgeInsets.all(1.5),
                      backgroundColor: genreState[index]
                          ? Colors.amber
                          : const Color(0xFF191A1C),
                      label: Text(
                        currentGenre,
                        style: TextStyle(
                          color: genreState[index]
                              ? Colors.black
                              : Colors.white,
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

            SizedBox(height: 10,),

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
              children: List.generate(conditionInfoList.length, (index) {
                final currentCondition = conditionInfoList[index];

                return GestureDetector(
                  onTap: () {
                    selectCondition(index);
                  },
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: conditionState[index] ? 1.0 : 0.5,
                    child: Chip(
                      padding: const EdgeInsets.all(1.5),
                      backgroundColor: conditionState[index]
                          ? Colors.amber
                          : const Color(0xFF191A1C),
                      label: Text(
                        currentCondition['code']!,
                        style: TextStyle(
                          color: conditionState[index]
                              ? Colors.black
                              : Colors.white,
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

            const Text(
              ''
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNormalTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }
}