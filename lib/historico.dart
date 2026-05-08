import 'package:flutter/material.dart';
import 'package:scriba/chat_model.dart'; 
import 'package:scriba/repositories/chat_repository.dart';

class HistoricoTela extends StatefulWidget {
  const HistoricoTela({super.key});

  @override
  State<HistoricoTela> createState() => _HistoricoTelaState();
}

class _HistoricoTelaState extends State<HistoricoTela> {
  final ChatRepository _chatRepository = ChatRepository.instance;

  @override
  Widget build(BuildContext context) {
    final conversas = List<ChatHistory>.from(_chatRepository.conversas)
      ..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Chats", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF31A89C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: conversas.isEmpty
          ? const Center(child: Text("Nenhum histórico disponível."))
          : ListView.builder(
              itemCount: conversas.length,
              itemBuilder: (context, index) {
                final chat = conversas[index];
                return Dismissible(
                  key: Key(chat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() => _chatRepository.removerConversa(chat));
                  },
                  child: ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF31A89C)),
                    title: Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("Atualizado em: ${chat.lastUpdate.hour}:${chat.lastUpdate.minute}"),
                    onTap: () {
                      Navigator.pop(context, chat);
                    },
                  ),
                );
              },
            ),
    );
  }
}