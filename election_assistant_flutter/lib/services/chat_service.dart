import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/nlp.dart';

class ChatService {
  ChatService({this.baseUrl = 'http://localhost:5000'});

  final String baseUrl;

  Future<ChatResponse> sendQuery(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('Backend error');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      String? image = data['image'] as String?;
      if (image != null && image.startsWith('/assets/')) {
        image = 'assets${image.substring(7)}';
        if (image.endsWith('.png.png')) {
          image = image.replaceFirst('.png.png', '.png');
        }
      }
      return ChatResponse(
        text: data['text'] as String? ?? '',
        image: image,
      );
    } catch (_) {
      return getResponse(query);
    }
  }
}
