import 'package:flutter/widgets.dart';

import '../core/models.dart';
import 'chat_controller.dart';

class ChatsViewModel extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  bool get searching => _searching;
  String get query => _query;

  void toggleSearch() {
    _searching = !_searching;
    if (!_searching) {
      _query = '';
      searchController.clear();
    }
    notifyListeners();
  }

  void closeSearch() {
    if (!_searching) return;
    _searching = false;
    _query = '';
    searchController.clear();
    notifyListeners();
  }

  void setQuery(String value) {
    final next = value.trim();
    if (next == _query) return;
    _query = next;
    notifyListeners();
  }

  List<Conversation> filtered(ChatController chat) {
    final value = _query.toLowerCase();
    final list = chat.orderedConversations();
    if (value.isEmpty) return list;
    return list.where((conv) {
      final title = chat.conversationTitle(conv).toLowerCase();
      final preview = (conv.last?.preview ?? '').toLowerCase();
      return title.contains(value) || preview.contains(value);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
