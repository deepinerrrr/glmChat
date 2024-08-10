import 'package:flutter/material.dart';
import 'package:glmchat/models/chat_message.dart';
import 'package:glmchat/services/openai_service.dart';
import 'package:intl/intl.dart';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ChatHistory> _chatHistories = []; // 用于存储所有聊天记录
  OpenAIService _openAIService = OpenAIService();
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  List<ChatHistory> get chatHistories => _chatHistories; // 获取聊天记录
  bool get isTyping => _isTyping;

  // 发送消息并监听响应流
  Future<void> sendMessage(String message) async {
    _messages.add(ChatMessage(message: message, isUser: true));
    _messages.add(ChatMessage(message: '', isUser: false)); // 添加空消息用于实时更新
    _isTyping = true;
    notifyListeners();

    try {
      final responseStream =
          await _openAIService.getChatResponseStream(_messages);

      responseStream.listen((data) {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex] = ChatMessage(
          message: data,
          isUser: false,
        );
        notifyListeners();
      }, onDone: () {
        _isTyping = false;
        _saveChatHistory(); // 保存聊天记录
        notifyListeners();
      }, onError: (error) {
        _isTyping = false;
        notifyListeners();
        print('Error in response stream: $error');
      });
    } catch (e) {
      _isTyping = false;
      notifyListeners();
      print('Error in sending message: $e');
    }
  }

  // 清空消息但保留历史记录
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  // 保存聊天记录
  void _saveChatHistory() {
    if (_messages.isNotEmpty) {
      final timestamp = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
      _chatHistories.add(ChatHistory(
        title: _messages.first.message,
        timestamp: timestamp,
        messages: List.from(_messages), // 创建消息列表的深拷贝
      ));
      notifyListeners();
    }
  }

  // 加载历史记录
  void loadChatHistory(int index) {
    _messages = List.from(_chatHistories[index].messages); // 加载指定历史记录
    notifyListeners();
  }
}

class ChatHistory {
  final String title;
  final String timestamp;
  final List<ChatMessage> messages;

  ChatHistory({
    required this.title,
    required this.timestamp,
    required this.messages,
  });
}
