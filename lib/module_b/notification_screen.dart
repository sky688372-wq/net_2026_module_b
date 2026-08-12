import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {


  //API로 넘어오는 정보가 없어서 임시 데이터를 불러와서 잘 작동하는지 확인함

  // 1. API 기본 설정 부분
  final String baseUrl = "https://connexChat-server.onrender.com/vinyl";

  // 토큰을 저장할 변수
  String _token = "";

  // 30초 주기 폴링(polling)을 위한 타이머 변수 선언
  Timer? _pollingTimer;

  // 알람 항목을 담을 리스트 및 안 읽은 개수 변수
  List<dynamic> notifications = [];
  int unreadCount = 0;

  // 테스트 데이터 변수
  // List<dynamic> testSet = [];

  // 로컬에서 token을 가져오는 함수
  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? "";
  }

  // 초기 데이터를 안전하게 불러오기 위한 래퍼 함수
  Future<void> _initializeData() async {
    await fetchToken(); // 토큰을 먼저 확실히 가져오기

    // 실제 통신 실행 (복구)
    fetchNotifications();

    // [주석 처리됨] 테스트 데이터 실행 방지
    // getTestData();
  }

  /*
  // 테스트 데이터를 채울 함수
  Future<void> getTestData() async {
    final test_url = "https://connexChat-server.onrender.com/vinyl/products";

    try {
      final response = await http.get(
          Uri.parse(test_url),
          headers: {
            "Authorization": "Bearer $_token"
          }
      );
      if (response.statusCode == 200) {
        debugPrint("테스트 데이터 통신 성공");

        // 한글 깨짐 방지
        final parseTestData = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          // API 응답 구조에서 'data' 배열을 가져옴
          testSet = parseTestData['data'] ?? [];

          // testSet을 알림 UI 규격에 맞게 변환하여 바로 notifications에 덮어씌움
          notifications = testSet.map((product) {
            return {
              'id': product['id'],
              'type': 'PRICE_DOWN',
              'title': '테스트 가격 인하',
              'albumName': product['albumName'],
              'artist': product['artist'],
              'albumImage': product['albumImage'],
              'previousPrice': (product['price'] ?? 0) + 15000,
              'currentPrice': product['price'] ?? 0,
              'isRead': false,
              'createdAt': DateTime.now().toIso8601String(),
            };
          }).toList();
        });
      } else {
        debugPrint("테스트 통신 오류, 오류 코드 ${response.statusCode}");
      }
    } catch(e) {
      debugPrint("테스트 통신 실패, $e");
    }
  }
  */

  // 2. 알림 목록 조회 함수 부분 : GET /notifications 통신
  Future<void> fetchNotifications() async {
    if (_token.isEmpty) return;

    final url = "$baseUrl/notifications";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $_token"
        },
      );

      if (response.statusCode == 200) {
        final parsedData = jsonDecode(utf8.decode(response.bodyBytes));

        if (parsedData['success'] == true) {
          if (mounted) {
            setState(() {
              notifications = parsedData['data']['notifications'] ?? [];
              unreadCount = parsedData['data']['unreadCount'] ?? 0;
            });
          }
        }
      } else {
        debugPrint("알림 통신 오류, 오류 코드 : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("알림 통신 오류, $e");
    }
  }

  // 3. 모두 읽음 처리 함수 부분 : PUT /notifications/read?all=true 통신
  Future<void> readAllNotifications() async {
    final url = "$baseUrl/notifications/read?all=true";
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token"
        },
      );
      if (response.statusCode == 200) {
        // 성공 시 데이터 갱신 (실제 통신 복구)
        fetchNotifications();
      }
    } catch (e) {
      debugPrint("모두 읽음 처리 오류, $e");
    }
  }

  // 4. 단건 읽음 처리 함수 부분 : PUT /notifications/read?id={id} 통신
  Future<void> readSingleNotification(int id) async {
    final url = "$baseUrl/notifications/read?id=$id";
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token"
        },
      );
      if (response.statusCode == 200) {
        // 성공 시 데이터 갱신 (실제 통신 복구)
        fetchNotifications();
      }
    } catch (e) {
      debugPrint("단건 읽음 처리 오류, $e");
    }
  }

  // 5. 전체 삭제 처리 함수 부분 : DELETE /notifications 통신
  Future<void> deleteAllNotifications() async {
    final url = "$baseUrl/notifications";
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $_token"
        },
      );
      if (response.statusCode == 200) {
        // 성공 시 데이터 갱신 (리스트가 비워짐)
        fetchNotifications();
      }
    } catch (e) {
      debugPrint("전체 삭제 처리 오류, $e");
    }
  }

  // 전체 삭제 확인 다이얼로그 띄우기 함수
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("알림 전체 삭제", style: TextStyle(color: Colors.white, fontSize: 16)),
          content: const Text("모든 알림을 삭제하시겠습니까?", style: TextStyle(color: Colors.white70, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteAllNotifications();
              },
              child: const Text("삭제", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 시간 포맷터 함수
  String _formatTimeAgo(String timeString) {
    try {
      DateTime time = DateTime.parse(timeString).toLocal();
      Duration diff = DateTime.now().difference(time);

      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      return '${diff.inDays}일 전';
    } catch (e) {
      return '';
    }
  }

  // 30초마다 갱신하는 부분 : 폴링 타이머 설정
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchNotifications();
    });
  }

  // 화면이 생성되면 해야할 부분
  @override
  void initState() {
    super.initState();
    _initializeData();

    // 폴링 로직 복구 (주석 해제)
    _startPolling();
  }

  // 화면 종료 시 처리하는 부분
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),

      // 6. 앱바 부분
      appBar: AppBar(
        backgroundColor: const Color(0xFF131313),
        title: const Text(
          "알림",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E1E1E),
            onSelected: (String value) {
              if (value == 'read_all') {
                readAllNotifications();
              } else if (value == 'delete_all') {
                _showDeleteDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'read_all',
                child: Text('모두 읽음', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem<String>(
                value: 'delete_all',
                child: Text('전체 삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          )
        ],
      ),

      // 7. 메인 콘텐츠 부분
      body: notifications.isEmpty ? _buildShowEmpty() : _buildNotificationList(),
    );
  }

  // 데이터가 없을 때 표시할 화면 부분
  Widget _buildShowEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "알림이 없습니다.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '관심 상품의 가격이 변동되면 알려드릴게요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          )
        ],
      ),
    );
  }

  // 데이터가 있을 때 렌더링할 리스트 부분
  Widget _buildNotificationList() {
    return RefreshIndicator(
      color: const Color(0xFFDAA84D),
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: fetchNotifications, // 당겨서 새로고침 실행 시 실제 통신으로 복구
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          final bool isRead = item['isRead'] ?? true;
          final int previousPrice = item['previousPrice'] ?? 0;
          final int currentPrice = item['currentPrice'] ?? 0;
          final bool isPriceDown = item['type'] == 'PRICE_DOWN';

          return GestureDetector(
            onTap: () {
              if (!isRead) {
                readSingleNotification(item['id']);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: isRead ? Colors.transparent : const Color(0xFF232323),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFF1E1E1E),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      item['albumImage'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.album, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isPriceDown ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isPriceDown ? Colors.blueAccent : Colors.redAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item['title'] ?? (isPriceDown ? '가격 인하' : '가격 인상'),
                                  style: TextStyle(
                                    color: isPriceDown ? Colors.blueAccent : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _formatTimeAgo(item['createdAt'] ?? ''),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${item['albumName']} - ${item['artist']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              "₩ ${previousPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, color: Colors.white54, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              "₩ ${currentPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}",
                              style: const TextStyle(
                                color: Color(0xFFDAA84D),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}