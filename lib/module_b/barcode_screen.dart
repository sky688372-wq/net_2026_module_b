import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:net_2026/detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 네이티브 채널
const _channel = MethodChannel('vinyl/barcode');

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  bool _granted = false; // 카메라 권한 여부
  bool _handled = false; // 바코드 중복 처리 방지

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_onNative);
    _checkPermission();
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  // ── 권한 확인 ──
  Future<void> _checkPermission() async {
    try {
      final has =
          await _channel.invokeMethod<bool>('hasCameraPermission') ?? false;
      if (has) {
        setState(() => _granted = true);
      } else {
        await _channel.invokeMethod('requestCameraPermission');
      }
    } catch (e) {
      // 네이티브 미연결 시 직접 입력 기능만 활성화
    }
  }

  // ── 네이티브 메시지 처리 ──
  Future<void> _onNative(MethodCall call) async {
    switch (call.method) {
      case 'onPermissionResult':
        final granted = call.arguments == true;
        if (granted) {
          setState(() => _granted = true);
        } else {
          _toast('카메라 권한이 필요합니다');
          if (mounted) Navigator.pop(context);
        }
        break;
      case 'onBarcode':
        final code = call.arguments as String?;
        if (code != null) _search(code);
        break;
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── 바코드 검색 및 상품 상세 화면 이동 ──
  Future<void> _search(String barcode) async {
    if (_handled) return;
    _handled = true;

    final cleanBarcode = barcode.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";
      final headers = {
        "Content-Type": "application/json",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

      int? productId;

      // [시도 1] 백엔드 단독 바코드 검색 API 호출 시도 (?barcode=번호)
      final searchUri = Uri.parse(
          'https://connexChat-server.onrender.com/vinyl/products?barcode=$cleanBarcode');
      final searchResponse = await http.get(searchUri, headers: headers);

      if (searchResponse.statusCode == 200) {
        final searchJson = jsonDecode(searchResponse.body);
        if (searchJson is Map<String, dynamic> && searchJson['id'] != null) {
          productId = searchJson['id'];
        } else if (searchJson is List && searchJson.isNotEmpty) {
          productId = searchJson.first['id'];
        }
      }

      // [시도 2] 단독 API로 못 찾은 경우 전체 목록 조회 후 매칭
      if (productId == null) {
        final listUri =
        Uri.parse('https://connexChat-server.onrender.com/vinyl/products');
        final response = await http.get(listUri, headers: headers);

        if (response.statusCode == 200) {
          final parsedJson = jsonDecode(response.body);

          List<dynamic> rawData = [];
          if (parsedJson is List) {
            rawData = parsedJson;
          } else if (parsedJson is Map<String, dynamic>) {
            rawData = parsedJson['data'] ??
                parsedJson['content'] ??
                parsedJson['items'] ??
                [];
          }

          if (rawData.isNotEmpty) {
            final matchedProduct = rawData.firstWhere(
                  (item) {
                // 1. barcode 필드 존재 시 비교
                var rawBarcode = item['barcode'] ??
                    item['barCode'] ??
                    item['barcodeNumber'] ??
                    item['code'];

                if (rawBarcode != null) {
                  String serverBarcode = rawBarcode is num
                      ? rawBarcode.toInt().toString()
                      : rawBarcode.toString().trim();
                  if (serverBarcode == cleanBarcode) return true;
                }

                // 2. 바코드 필드가 없는 백엔드 환경에서 스캔 값과 상품 ID 비교 예외 처리
                if (item['id'] != null) {
                  String idString = item['id'].toString().trim();
                  if (idString == cleanBarcode) return true;
                }

                return false;
              },
              orElse: () => null,
            );

            if (matchedProduct != null) {
              productId = matchedProduct['id'];
            }
          }
        }
      }

      if (!mounted) return;

      if (productId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '스캔 성공! [바코드: $cleanBarcode] -> [상품 ID: $productId]',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFDFAC42),
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(id: productId!),
          ),
        );
      } else {
        _toast('바코드 "$cleanBarcode"에 해당하는 등록된 상품이 없습니다.\n(서버 응답 데이터에 barcode 필드 누락)');
        _handled = false;
      }
    } catch (e) {
      _toast('네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      print('❌ 에러 발생: $e');
      _handled = false;
    }
  }

  // ── 직접 입력 다이얼로그 ──
  Future<void> _manualInput() async {
    final controller = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '바코드 직접 입력',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '바코드 번호 또는 상품 ID 입력',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(
              '검색',
              style: TextStyle(color: Color(0xFFE8B04B)),
            ),
          ),
        ],
      ),
    );
    if (barcode != null && barcode.isNotEmpty) _search(barcode);
  }

  @override
  Widget build(BuildContext context) {
    const double scanW = 280;
    const double scanH = 170;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 프리뷰 (네이티브 CameraView)
          if (_granted) const Positioned.fill(child: NativeCameraView()),

          // 스캔 영역 외 반투명 오버레이
          _buildDarkOverlay(scanW, scanH),

          // 스캔 프레임 및 중앙 스캔 라인
          Center(
            child: SizedBox(
              width: scanW,
              height: scanH,
              child: Stack(
                children: [
                  _corner(top: 0, left: 0),
                  _corner(top: 0, right: 0),
                  _corner(bottom: 0, left: 0),
                  _corner(bottom: 0, right: 0),
                  Center(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: const Color(0xFFE8B04B).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 상단 타이틀 및 안내문구
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        '바코드 검색',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const Text(
                  '상품의 바코드를 화면 중앙에 맞춰주세요',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),

          // 하단 직접 입력 버튼
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: TextButton.icon(
                onPressed: _manualInput,
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  '직접 입력',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 스캔 구역 외 반투명 배경
  Widget _buildDarkOverlay(double scanW, double scanH) {
    final overlay = Colors.black.withOpacity(0.55);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final left = (w - scanW) / 2;
        final top = (h - scanH) / 2;
        return Stack(
          children: [
            Positioned(
              left: 0, top: 0, width: w, height: top,
              child: ColoredBox(color: overlay),
            ),
            Positioned(
              left: 0, top: top + scanH, width: w, height: h - top - scanH,
              child: ColoredBox(color: overlay),
            ),
            Positioned(
              left: 0, top: top, width: left, height: scanH,
              child: ColoredBox(color: overlay),
            ),
            Positioned(
              left: left + scanW, top: top, width: left, height: scanH,
              child: ColoredBox(color: overlay),
            ),
          ],
        );
      },
    );
  }

  // ㄱ자 모서리 마커
  Widget _corner({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: Color(0xFFE8B04B), width: 3)
                : BorderSide.none,
            bottom: bottom != null
                ? const BorderSide(color: Color(0xFFE8B04B), width: 3)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: Color(0xFFE8B04B), width: 3)
                : BorderSide.none,
            right: right != null
                ? const BorderSide(color: Color(0xFFE8B04B), width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// Android Hybrid Composition 뷰
class NativeCameraView extends StatelessWidget {
  const NativeCameraView({super.key});

  static const String viewType = 'vinyl/barcode-camera';

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const {},
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}