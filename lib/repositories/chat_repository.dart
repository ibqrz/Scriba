import 'package:scriba/api_service.dart';
import 'package:scriba/chat_model.dart';

class ChatRepository {
  ChatRepository._internal();

  static final ChatRepository instance = ChatRepository._internal();

  final List<ChatHistory> _conversas = [];

  List<ChatHistory> get conversas => _conversas;

  ChatHistory criarConversa({
    required String titulo,
  }) {
    final conversa = ChatHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titulo,
      messages: [],
      lastUpdate: DateTime.now(),
    );
    _conversas.add(conversa);
    return conversa;
  }

  void removerConversa(ChatHistory conversa) {
    _conversas.remove(conversa);
  }

  void limparConversas() {
    _conversas.clear();
  }

  Future<String> responderMensagem({
    required ChatHistory conversa,
    required String mensagemUsuario,
    required String tituloNota,
  }) async {
    final resultadoApi = await ApiService.enviarPromptIa(prompt: mensagemUsuario);

    if (resultadoApi != null && resultadoApi['success'] == true) {
      final data = resultadoApi['data'];
      if (data is Map<String, dynamic>) {
        final possiveisCampos = [
          data['message'],
          data['response'],
          data['answer'],
          data['text'],
        ];

        for (final campo in possiveisCampos) {
          if (campo != null && campo.toString().trim().isNotEmpty) {
            return campo.toString();
          }
        }
      }

      return 'Recebi sua mensagem sobre "$tituloNota" e já estou analisando.';
    }

    return "Entendi! Como posso ajudar com '$tituloNota'?";
  }
}
