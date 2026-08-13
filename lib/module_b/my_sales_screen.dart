import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {
  //토큰, 유저 id를 불러오는 함수 : 토큰이 존재함을 확인함 -> 고로 애는 범인이 아님
  var _token;
  var _userId;

  File? _selectedImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  // 화면이 로드될 때 토큰을 불러오도록 initState 추가
  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('token') ?? '';
    _userId = prefs.getInt('userId') ?? 0;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _selectedImage = File(image.path);
        // 서버에서 요구하는 Base64 형식에 맞게 접두사 추가
        _base64Image = "data:image/jpeg;base64,$base64String";
      });
    }
  }

  //상품을 등록할 수 있도록 해주는 함수
  Future<void> submitProduct() async {
    // 1. 선택된 인덱스 찾기
    int genreIndex = genreState.indexOf(true);
    int conditionIndex = conditionState.indexOf(true);
    int tradeIndex = tradeTypeState.indexOf(true);

    if (genreIndex == -1 || conditionIndex == -1 || tradeIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 선택 항목(장르, 상태, 거래방식)을 선택해주세요.')),
      );
      return;
    }

    final tradeMethodCodes = ['DIRECT', 'DELIVERY', 'BOTH'];
    final url = "https://connexChat-server.onrender.com/vinyl/products?userId=$_userId";

    try {
      String finalImageUrl = "https://connexChat-server.onrender.com/vinyl/images/album/default.jpg";

      if (_base64Image != null) {
        final uploadUrl = "https://connexChat-server.onrender.com/vinyl/upload/image?userId=$_userId";
        final uploadResponse = await http.post(
          Uri.parse(uploadUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: jsonEncode({
            'image': _base64Image,
            'type': 'ALBUM'
          }),
        );

        if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
          final uploadData = jsonDecode(uploadResponse.body);
          finalImageUrl = uploadData['data']['imageUrl']; // 서버에서 반환한 URL
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
          );
          return; // 업로드 실패 시 상품 등록 중단
        }
      }

      // 2. 최종 상품 등록 요청
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'albumName': albumNameCtrl.text,
          'artist': albumArtistCtrl.text,
          'genre': genreList[genreIndex],
          'condition': conditionInfoList[conditionIndex]['code'],
          'price': int.tryParse(albumPriceCtrl.text) ?? 0,
          'tradeMethod': tradeMethodCodes[tradeIndex],
          'barcode': barCodeController.text,
          'description': descriptionController.text,
          'albumImage': finalImageUrl,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품 등록 성공'))
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          albumNameCtrl.clear();
          albumArtistCtrl.clear();
          albumPriceCtrl.clear();
          barCodeController.clear();
          descriptionController.clear();
          setState(() {
            _selectedImage = null;
            _base64Image = null;
          });
        }
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('상품 등록 실패 ${response.statusCode}'))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 등록 실패 $e'))
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
    barCodeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // 장르를 담을 리스트
  final List<String> genreList = [
    'ROCK', 'JAZZ', 'POP', 'HIPHOP', 'ELECTRONIC', 'CLASSICAL', 'RNB_SOUL', 'ETC',
  ];

  // 장르 선택 확인 트리거
  List<bool> genreState = List.generate(8, (_) => false);

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
    {'code': 'SS', 'fullName': 'Still Sealed', 'description': '미개봉 새상품. 완벽한 상태입니다.'},
    {'code': 'M', 'fullName': 'Mint', 'description': '개봉했으나 새것과 다름없는 완벽한 상태입니다.'},
    {'code': 'NM', 'fullName': 'Near Mint', 'description': '거의 새것에 가까운 상태로, 미세한 사용감만 있습니다.'},
    {'code': 'EX', 'fullName': 'Excellent', 'description': '전체적으로 깨끗하며, 약간의 사용감이 있습니다.'},
    {'code': 'VG+', 'fullName': 'Very Good Plus', 'description': '양호한 상태로, 재생에 문제가 없습니다.'},
    {'code': 'VG', 'fullName': 'Very Good', 'description': '사용감이 있으나 재생에 큰 문제가 없습니다.'},
    {'code': 'G', 'fullName': 'Good', 'description': '사용감이 많으나 재생은 가능합니다.'},
  ];

  List<bool> conditionState = List.generate(7, (_) => false);

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
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // 보여주신 이미지 배경색과 비슷하게 설정
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, color: Colors.white.withValues(alpha: 0.5), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        '상품 이미지를 등록하세요',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '터치하여 카메라/갤러리 선택',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

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

              // 6. 거래 방식
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

              // 바코드 번호 입력 부분
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

              // 상품 설명
              const Text(
                '상품 설명 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFFDAA84D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)
                        )
                    ),
                    onPressed: () {
                      submitProduct();
                    },
                    child: const Text(
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