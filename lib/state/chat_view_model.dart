import 'dart:async';

import 'package:flutter/widgets.dart';

import 'chat_controller.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatController chat;
  final String conversationId;
  final TextEditingController input;

  Timer? _typingTimer;
  bool _dragging = false;

  ChatViewModel(this.chat, this.conversationId)
      : input = TextEditingController(
          text: chat.convs[conversationId]?.draft ?? '',
        ) {
    input.addListener(_onInputChanged);
  }

  bool get dragging => _dragging;

  bool get canSend => input.text.trim().isNotEmpty;

  void _onInputChanged() {
    final text = input.text;
    chat.setDraft(conversationId, text);
    chat.sendTyping(text.trim().isNotEmpty);
    _typingTimer?.cancel();
    if (text.trim().isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        chat.sendTyping(false);
      });
    }
    notifyListeners();
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    _typingTimer?.cancel();
    input.clear();
    chat.setDraft(conversationId, '');
    chat.sendTyping(false);
    await chat.sendText(text);
  }

  void setDragging(bool value) {
    if (_dragging == value) return;
    _dragging = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    input.removeListener(_onInputChanged);
    input.dispose();
    super.dispose();
  }
}
