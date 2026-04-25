class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class ChatHistory {
  final String id;
  final String title;
  final List<Message> messages;
  DateTime lastUpdate;

  ChatHistory({
    required this.id,
    required this.title,
    required this.messages,
    required this.lastUpdate,
  });
}

List<ChatHistory> listaDeConversas = [];