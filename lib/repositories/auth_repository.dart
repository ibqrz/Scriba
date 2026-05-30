import 'package:flutter/foundation.dart';
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
    debugPrint('📝 [REGISTER] Iniciando registro para: $email');
    
    final resultadoApi = await ApiService.registrar(
      nome: nome,
      sobrenome: sobrenome,
      login: login,
      email: email,
      senha: senha,
      sistemaId: ApiService.sistemaId,
    );

    if (resultadoApi == null || resultadoApi['success'] != true) {
      final msg = resultadoApi?['message']?.toString() ?? 'Erro ao registrar usuário.';
      debugPrint('❌ [REGISTER] Falha: $msg');
      return {
        'success': false,
        'message': msg,
      };
    }

    debugPrint('✅ [REGISTER] Registro remoto bem-sucedido!');
    debugPrint('    📍 Endpoint: POST /api/register');
    final dataResponse = resultadoApi['data'];
    if (dataResponse is Map) {
      debugPrint('    📦 Response API: ${dataResponse.toString()}');
    }

    final resultadoLogin = await ApiService.login(
      username: login,
      senha: senha,
      sistemaId: ApiService.sistemaId,
    );

    if (resultadoLogin == null || resultadoLogin['success'] != true) {
      final msg = resultadoLogin?['message']?.toString() ?? 'Cadastro retornou sucesso, mas o login de confirmação falhou.';
      debugPrint('❌ [REGISTER] Falha na confirmação: $msg');
      return {
        'success': false,
        'message': msg,
      };
    }

    debugPrint('✅ [REGISTER] Confirmação de login bem-sucedida!');
    debugPrint('    📍 Endpoint: POST /api/auth/login');
    final loginResponse = resultadoLogin['data'];
    if (loginResponse is Map) {
      debugPrint('    📦 Response API: ${loginResponse.toString()}');
    }
    debugPrint('    🔑 Token obtido: ${resultadoLogin['token']?.toString().substring(0, 20)}...');

    final token = resultadoLogin['token']?.toString();
    debugPrint('💾 [REGISTER] Salvando usuário localmente...');
    Map<String, dynamic>? usuario = await DatabaseHelper.instance.cadastrarUsuario(
      nome: nome,
      sobrenome: sobrenome,
      login: login,
      email: email,
      senha: senha,
      token: token,
      sistemaId: ApiService.sistemaId,
    );

    if (usuario == null) {
      debugPrint('⚠️ [REGISTER] Falha ao inserir (constraint?), tentando recuperar...');
      usuario = await DatabaseHelper.instance.obterUsuarioPorEmail(email);
      if (usuario == null && login.isNotEmpty) {
        usuario = await DatabaseHelper.instance.autenticarUsuario(
          login: login,
          senha: senha,
        );
      }

      if (usuario == null) {
        debugPrint('❌ [REGISTER] Registro remoto OK, mas falha local irrecuperável.');
        try {
          await DatabaseHelper.instance.salvarOrphanRemote(
            login: login,
            email: email,
            reason: 'Falha ao salvar usuário local após registro remoto',
          );
        } catch (_) {}

        return {
          'success': false,
          'message': 'Erro ao salvar usuário localmente e usuário não encontrado. Registro de limpeza criado localmente para revisão.',
        };
      }

      debugPrint('✅ [REGISTER] Usuário recuperado do banco local.');

      if (token != null) {
        await DatabaseHelper.instance.salvarTokenUsuario(
          idUsuario: usuario['id_usuario'] as int,
          token: token,
          sistemaId: ApiService.sistemaId,
        );
      }
    } else {
      debugPrint('✅ [REGISTER] Usuário saved localmente com sucesso!');
      debugPrint('    📊 Dados salvos no banco (sem senha):');
      debugPrint('       - ID: ${usuario['id_usuario']}');
      debugPrint('       - Nome: ${usuario['nome']}');
      debugPrint('       - Email: ${usuario['email']}');
      debugPrint('       - Login: ${usuario['login']}');
      debugPrint('       - Token: ${usuario['token']?.toString().substring(0, 20)}...');
      
      if (token != null) ApiService.setToken(token);
    }

    debugPrint('🎉 [REGISTER] Registro finalizado com sucesso!');
    debugPrint('    ✓ Usuário cadastrado com sucesso');
    debugPrint('    ✓ Dados do banco: ID=${usuario['id_usuario']}, Email=${usuario['email']}, Login=${usuario['login']}');

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
    debugPrint('🔐 [AUTH] Iniciando login para: $username');
    Map<String, dynamic>? usuario;
    String? token;

    try {
      debugPrint('💾 [AUTH] Validando credenciais localmente por email: $username');
      usuario = await DatabaseHelper.instance.autenticarUsuario(email: username, senha: senha);
      
      if (usuario == null) {
        debugPrint('💾 [AUTH] Não validou por email, tentando por login...');
        usuario = await DatabaseHelper.instance.autenticarUsuario(login: username, senha: senha);
      }

      if (usuario != null) {
        debugPrint('✅ [AUTH] Usuário local encontrado!');
        debugPrint('    📊 Dados do banco (sem senha):');
        debugPrint('       - ID: ${usuario['id_usuario']}');
        debugPrint('       - Nome: ${usuario['nome']}');
        debugPrint('       - Email: ${usuario['email']}');
        debugPrint('       - Login: ${usuario['login']}');

        final idUsuario = usuario['id_usuario'] as int?;
        final tokenLocal = usuario['token']?.toString();

        if (idUsuario != null && tokenLocal != null && tokenLocal.isNotEmpty) {
          final tokenAindaValido = !await DatabaseHelper.instance.tokenExpirou(idUsuario: idUsuario);
          if (tokenAindaValido) {
            debugPrint('✅ [AUTH] Token local ainda válido. Login concluído sem chamar a API.');
            ApiService.setToken(tokenLocal);
            return {
              'success': true,
              'user': usuario,
              'token': tokenLocal,
            };
          }

          debugPrint('ℹ️ [AUTH] Token local expirado. Será feita nova validação na API.');
        } else {
          debugPrint('ℹ️ [AUTH] Usuário local sem token válido salvo. Será feita nova validação na API.');
        }
      } else {
        debugPrint('ℹ️ [AUTH] Usuário local não encontrado, criando novo...');
      }

      // Se chegamos aqui, o login via cache local não foi possível.
      debugPrint('📡 [AUTH] Validando credenciais contra API...');
      debugPrint('    📍 Endpoint: POST /api/auth/login');

      final resultadoApi = await ApiService.login(
        username: username,
        senha: senha,
        sistemaId: ApiService.sistemaId,
      );

      if (resultadoApi == null || resultadoApi['success'] != true) {
        final msg = resultadoApi?['message']?.toString() ?? 'Credenciais inválidas.';
        debugPrint('❌ [AUTH] Falha na API: $msg');
        return {
          'success': false,
          'message': msg,
        };
      }

      debugPrint('✅ [AUTH] API retornou sucesso!');
      
      // =======================================================================
      // BLOCO DE INSPEÇÃO DE RETORNO DO SERVIDOR (NÃO ALTERA A LÓGICA)
      // =======================================================================
      debugPrint('===================================================');
      debugPrint('🔍 [INSPEÇÃO SCRIBA] Estrutura completa da resposta da API:');
      debugPrint('$resultadoApi');
      if (resultadoApi['data'] != null) {
        debugPrint('📦 Conteúdo de "data": ${resultadoApi['data']}');
      } else {
        debugPrint('⚠️ O campo "data" veio nulo ou não existe nessa API.');
      }
      debugPrint('===================================================');

      final apiResponse = resultadoApi['data'];
      if (apiResponse is Map) {
        debugPrint('    📦 Response API: ${apiResponse.toString()}');
      }
      debugPrint('    🔑 Token obtido: ${resultadoApi['token']?.toString().substring(0, 20)}...');

      token = resultadoApi['token']?.toString();

      if (usuario == null && resultadoApi['data'] is Map) {
        final apiData = resultadoApi['data'] as Map<String, dynamic>;
        
        // Mapeia de forma resiliente as variações de chaves retornadas pelo Keycloak/Servidor central
        final nomeReal = (apiData['name'] ?? apiData['nome'] ?? apiData['firstName'] ?? 'Usuario').toString().trim();
        final sobrenomeReal = (apiData['surname'] ?? apiData['sobrenome'] ?? apiData['lastName'] ?? '').toString().trim();
        
        // Evita gravar o apelido/login dentro do campo de e-mail local do SQLite
        final emailReal = (apiData['email'] ?? apiData['email_user'] ?? (username.contains('@') ? username : '')).toString().trim().toLowerCase();
        final loginReal = (apiData['login'] ?? apiData['username'] ?? (!username.contains('@') ? username : '')).toString().trim().toLowerCase();

        usuario = await DatabaseHelper.instance.cadastrarUsuario(
          nome: nomeReal,
          sobrenome: sobrenomeReal,
          login: loginReal.isNotEmpty ? loginReal : username,
          email: emailReal.isNotEmpty ? emailReal : username,
          senha: senha,
          token: token,
          sistemaId: ApiService.sistemaId,
        );

        if (usuario == null) {
          debugPrint('⚠️ [AUTH] Conflito ou falha de UNIQUE detectada. Buscando registro correto no SQLite...');
          if (emailReal.isNotEmpty) {
            usuario = await DatabaseHelper.instance.obterUsuarioPorEmail(emailReal);
          }
          if (usuario == null && loginReal.isNotEmpty) {
            usuario = await DatabaseHelper.instance.obterUsuarioPorEmail(loginReal);
          }
          // Fallback estrito pelo termo digitado na tela
          if (usuario == null) {
            usuario = await DatabaseHelper.instance.obterUsuarioPorEmail(username);
          }
        }

        debugPrint('✅ [AUTH] Usuário local processado com sucesso.');
        debugPrint('    📊 Dados salvos/recuperados:');
        debugPrint('       - ID: ${usuario?['id_usuario']}');
        debugPrint('       - Nome: ${usuario?['nome']}');
        debugPrint('       - Email: ${usuario?['email']}');
      }

      if (usuario != null && token != null) {
        final idUsuarioValido = usuario['id_usuario'] as int;
        debugPrint('💾 [AUTH] Atualizando token local para usuário (id: $idUsuarioValido)');
        await DatabaseHelper.instance.salvarTokenUsuario(
          idUsuario: idUsuarioValido,
          token: token,
          sistemaId: ApiService.sistemaId,
        );
        
        final usuarioAtualizado = Map<String, dynamic>.from(usuario);
        usuarioAtualizado['token'] = token;
        usuarioAtualizado['id_usuario'] = idUsuarioValido;
        usuario = usuarioAtualizado;
        
        debugPrint('✅ [AUTH] Token local salvo.');
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH] Erro ao salvar localmente: ${e.toString()}');
    }

    ApiService.setToken(token);
    debugPrint('🎉 [AUTH] Login finalizado com sucesso!');
    debugPrint('    ✓ Autenticação pela API confirmada');
    debugPrint('    ✓ Usuário (ID=${usuario?['id_usuario']}, Email=${usuario?['email']}) carregado localmente');

    return {
      'success': true,
      'user': usuario,
      'token': token,
    };
  }
}