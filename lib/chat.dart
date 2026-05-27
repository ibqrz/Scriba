import 'package:flutter/material.dart';
import 'package:scriba/chat_model.dart'; 
import 'package:scriba/historico.dart';
import 'package:scriba/repositories/chat_repository.dart';

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
  final ChatRepository _chatRepository = ChatRepository.instance;
  final TextEditingController _controller = TextEditingController();
  late ChatHistory _conversaAtual;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conversaAtual = _chatRepository.criarConversa(
      titulo: widget.tituloNota.isEmpty ? "Nova Conversa" : widget.tituloNota,
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final textoUsuario = _controller.text.trim();

    // Mostra a mensagem do usuário imediatamente
    setState(() {
      _conversaAtual.messages.add(Message(text: textoUsuario, isUser: true));
      _conversaAtual.lastUpdate = DateTime.now();
    });
    _controller.clear();

    // Solicita resposta da IA e atualiza o histórico quando chegar
    setState(() {
      _isLoading = true;
    });

    await _chatRepository.responderMensagem(
      conversa: _conversaAtual,
      mensagemUsuario: textoUsuario,
      tituloNota: widget.tituloNota,
    );

    setState(() {
      _isLoading = false;
    });

    _scrollToBottom();
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
              controller: _scrollController,
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
          if (_isLoading) Padding(
            padding: const EdgeInsets.only(left:16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Assistente está respondendo...', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ),
          buildInputBar(),
        ],
      ),
    );
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll_controllerHasClients()) return; 
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _scroll_controllerHasClients() {
    // helper to avoid lint warnings when accessing controller in tests
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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