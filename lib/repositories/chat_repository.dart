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
    // O `ChatTela` já adiciona a mensagem do usuário ao histórico local,
    // então aqui apenas preparamos o histórico a ser enviado.
    // Limita o histórico para as últimas 10 mensagens para reduzir payload.
    final recent = conversa.messages.length > 10
        ? conversa.messages.sublist(conversa.messages.length - 10)
        : conversa.messages;

    final historyPayload = recent
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    print('[ChatRepository] Enviando prompt para IA. titulo: $tituloNota, prompt: $mensagemUsuario');

    final resultadoApi = await ApiService.enviarPromptIa(
      prompt: mensagemUsuario,
      history: historyPayload,
      titulo: tituloNota,
    );

    print('[ChatRepository] Resultado da API: $resultadoApi');

    String respostaTexto;
    if (resultadoApi != null && resultadoApi['success'] == true) {
      final data = resultadoApi['data'];
      if (data is Map<String, dynamic>) {
        final possiveisCampos = [
          data['message'],
          data['response'],
          data['answer'],
          data['text'],
        ];

        String? encontrado;
        for (final campo in possiveisCampos) {
          if (campo != null && campo.toString().trim().isNotEmpty) {
            encontrado = campo.toString();
            break;
          }
        }

        respostaTexto = encontrado ?? 'Recebi sua mensagem sobre "$tituloNota" e já estou analisando.';
      } else if (resultadoApi['data'] is String) {
        respostaTexto = resultadoApi['data'] as String;
      } else {
        respostaTexto = 'Recebi sua mensagem sobre "$tituloNota" e já estou analisando.';
      }
    } else {
      final errorMsg = resultadoApi?['message'] ?? 'Erro desconhecido';
      respostaTexto = "❌ Erro: $errorMsg";
      print('[ChatRepository] Erro detalhado: $errorMsg');
    }

    // Adiciona a resposta da IA ao histórico local
    conversa.messages.add(Message(text: respostaTexto, isUser: false));
    conversa.lastUpdate = DateTime.now();

    return respostaTexto;
  }
}
