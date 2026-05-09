import 'package:scriba/database_helper.dart';

class NoteRepository {
  Future<List<Map<String, dynamic>>> listarNotas(int idUsuario) {
    return DatabaseHelper.instance.getNotas(idUsuario);
  }

  Future<int> salvarNota({
    required String titulo,
    required String conteudo,
    required int idUsuario,
    int? notaId,
  }) {
    if (notaId == null) {
      return DatabaseHelper.instance.inserirNota(
        titulo: titulo,
        conteudo: conteudo,
        idUsuario: idUsuario,
      );
    }

    return DatabaseHelper.instance.atualizarNota(
      idNota: notaId,
      idUsuario: idUsuario,
      titulo: titulo,
      conteudo: conteudo,
    );
  }

  Future<int> excluirNota({
    required int idNota,
    required int idUsuario,
  }) {
    return DatabaseHelper.instance.excluirNota(
      idNota: idNota,
      idUsuario: idUsuario,
    );
  }
}
