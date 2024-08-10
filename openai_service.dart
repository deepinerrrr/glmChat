import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:glmchat/models/chat_message.dart';

class OpenAIService {
  final String apiKey = 'd69361ec7b7b18e63dd30af475425f3e.149Yh9cZNR3maNow';

  Future<Stream<String>> getChatResponseStream(
      List<ChatMessage> chatHistory) async {
    final url =
        Uri.parse('https://open.bigmodel.cn/api/paas/v4/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // 转换聊天历史记录为模型可理解的格式
    final messages = chatHistory.map((message) {
      return {
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.message,
      };
    }).toList();

    final body = json.encode({
      'model': 'glm-4-alltools',
      'messages': messages,
      'stream': true,
    });

    try {
      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final response = await request.send();

      if (response.statusCode == 200) {
        final StringBuffer buffer = StringBuffer();

        return response.stream
            .transform(utf8.decoder)
            .where((line) => line.startsWith('data: '))
            .map((line) {
          final jsonString = line.substring(6).trim();
          try {
            final decoded = json.decode(jsonString);
            final content = decoded['choices'][0]['delta']['content'] ?? '';
            buffer.write(content); // 将内容添加到 StringBuffer 中
            return buffer.toString(); // 返回拼接后的完整消息
          } catch (e) {
            print('Error decoding JSON: $e');
            return buffer.toString(); // 即使出错也返回已有内容
          }
        }).where((content) => content.isNotEmpty);
      } else {
        print('Failed with status code: ${response.statusCode}');
        throw Exception('Failed to fetch response');
      }
    } catch (e) {
      print('Request error: $e');
      rethrow;
    }
  }
}
