import 'package:flutter/material.dart';
import 'chat_model.dart'; 
import 'historico.dart';

class ChatTela extends StatefulWidget {
  final String textoNota;
  final String tituloNota;

  const ChatTela({
    super.key, 
    required this.textoNota, 
    required this.tituloNota,
  });

  @override
  State<ChatTela> createState() => _ChatTelaState();
}

class _ChatTelaState extends State<ChatTela> {
  final TextEditingController _controller = TextEditingController();
  late ChatHistory _conversaAtual;

  @override
  void initState() {
    super.initState();
    _conversaAtual = ChatHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.tituloNota.isEmpty ? "Nova Conversa" : widget.tituloNota,
      messages: [],
      lastUpdate: DateTime.now(),
    );
    listaDeConversas.add(_conversaAtual);
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _conversaAtual.messages.add(Message(text: _controller.text, isUser: true));
      _conversaAtual.lastUpdate = DateTime.now();
      
      _conversaAtual.messages.add(Message(
        text: "Entendi! Como posso ajudar com '${widget.tituloNota}'?", 
        isUser: false
      ));
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF31A89C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Chat IA", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () async {
              final selecionada = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoricoTela()),
              );
              if (selecionada != null && selecionada is ChatHistory) {
                setState(() => _conversaAtual = selecionada);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _conversaAtual.messages.length,
              itemBuilder: (context, index) {
                final msg = _conversaAtual.messages[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: msg.isUser 
                    ? buildUserBubble(msg.text) 
                    : buildIABubble(msg.text),
                );
              },
            ),
          ),
          buildInputBar(),
        ],
      ),
    );
  }
  Widget buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 50),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget buildIABubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 50),
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Color(0xFF31A89C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Pergunte algo...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.emoji_objects_outlined, color: Color(0xFF31A89C)),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF31A89C)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(color: Color(0xFF31A89C), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}