import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF131313),
      appBar: AppBar(
        backgroundColor: Color(0xFF131313),
        title: Text(
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E1E1E), // 팝업 메뉴 배경색
            onSelected: (String value) {
              if (value == 'read_all') {
                // 모두 읽음 처리 로직
              } else if (value == 'delete_all') {
                // 전체 삭제 처리 로직
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'read_all',
                child: Text(
                  '모두 읽음',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete_all',
                child: Text(
                  '전체 삭제',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
