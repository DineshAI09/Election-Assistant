import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

class ElectionAssistantApp extends StatelessWidget {
  const ElectionAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Election Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF1D4ED8),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ChatScreen(),
    );
  }
}
