import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/chat_controller.dart';
import '../state/chat_view_model.dart';
import 'adaptive.dart';
import 'screens/chat_screen.dart';

Future<void> openChatScreen(BuildContext context, String conversationId) {
  final controller = context.read<ChatController>();
  controller.openConversation(conversationId);
  return Navigator.of(context).push<void>(
    adaptivePageRoute(
      ChangeNotifierProvider<ChatViewModel>(
        create: (_) => ChatViewModel(controller, conversationId),
        child: ChatScreen(conversationId: conversationId),
      ),
    ),
  );
}
