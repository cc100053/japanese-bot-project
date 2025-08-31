import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(JapaneseColdBotApp());
}

class JapaneseColdBotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Japanese Cold Bot',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'NotoSansJP',
      ),
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}