import 'package:scriba/api_service.dart';
import 'package:scriba/database_helper.dart';

class AuthRepository {
  Future<Map<String, dynamic>?> registrarUsuario({
    required String nome,
    required String sobrenome,
    required String login,
    required String email,
    required String senha,
  }) async {
    final resultadoApi = await ApiService.registrar(
      nome: nome,
      sobrenome: sobrenome,
      login: login,
      email: email,
      senha: senha,
      sistemaId: ApiService.sistemaId,
    );

    if (resultadoApi == null || resultadoApi['success'] != true) {
      return {
        'success': false,
        'message': resultadoApi?['message']?.toString() ?? 'Erro ao registrar usuário.',
      };
    }

    final resultadoLogin = await ApiService.login(
      username: login,
      senha: senha,
      sistemaId: ApiService.sistemaId,
    );

    if (resultadoLogin == null || resultadoLogin['success'] != true) {
      return {
        'success': false,
        'message': resultadoLogin?['message']?.toString() ?? 'Cadastro retornou sucesso, mas o login de confirmação falhou.',
      };
    }

    final token = resultadoLogin['token']?.toString();
    final usuario = await DatabaseHelper.instance.cadastrarUsuario(
      nome: nome,
      sobrenome: sobrenome,
      login: login,
      email: email,
      senha: senha,
      token: token,
      sistemaId: ApiService.sistemaId,
    );

    if (usuario == null) {
      return {
        'success': false,
        'message': 'Erro ao salvar usuário localmente.',
      };
    }

    if (token != null) {
      ApiService.setToken(token);
    }

    return {
      'success': true,
      'user': usuario,
      'token': token,
    };
  }

  Future<Map<String, dynamic>?> autenticarUsuario({
    required String username,
    required String senha,
  }) async {
    final resultadoApi = await ApiService.login(
      username: username,
      senha: senha,
      sistemaId: ApiService.sistemaId,
    );

    if (resultadoApi == null || resultadoApi['success'] != true) {
      return {
        'success': false,
        'message': resultadoApi?['message']?.toString() ?? 'Credenciais inválidas.',
      };
    }

    final token = resultadoApi['token']?.toString();
    Map<String, dynamic>? usuario = await DatabaseHelper.instance.obterUsuarioPorEmail(username);

    if (usuario != null && token != null) {
      await DatabaseHelper.instance.salvarTokenUsuario(
        idUsuario: usuario['id_usuario'] as int,
        token: token,
        sistemaId: ApiService.sistemaId,
      );
    } else if (usuario == null && token != null) {
      final apiData = resultadoApi['data'];
      usuario = await DatabaseHelper.instance.cadastrarUsuario(
        nome: apiData['name'] ?? 'Usuario',
        sobrenome: apiData['surname'],
        login: username,
        email: username,
        senha: senha,
        token: token,
        sistemaId: ApiService.sistemaId,
      );
    }

    if (usuario == null) {
      return {
        'success': false,
        'message': 'Erro ao processar login.',
      };
    }

    ApiService.setToken(token);

    return {
      'success': true,
      'user': usuario,
      'token': token,
    };
  }
}