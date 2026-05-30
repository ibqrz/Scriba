import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // URLs das APIs
  static const String _authUrl = 'https://mobile-ios-login.zani0x03.eti.br/api';
  static const String _iaUrl = 'https://mobile-ios-ia.zani0x03.eti.br/api';
  static const String _webProxyFromEnv = String.fromEnvironment(
    'SCRIBA_PROXY_BASE_URL',
    defaultValue: '',
  );
  static const String _sistemaId = '64b511cc-1392-4d37-85af-9c581961de40'; 

  static String? _token;
  static String? _cachedWebProxyBaseUrl;

  static Future<String> _resolveWebProxyBaseUrl() async {
    if (!kIsWeb) return '';
    if (_cachedWebProxyBaseUrl != null) return _cachedWebProxyBaseUrl!;

    final List<String> candidates = [];
    if (_webProxyFromEnv.trim().isNotEmpty) candidates.add(_webProxyFromEnv.trim());

    final uriBase = Uri.base;
    if (uriBase.hasAuthority && uriBase.host.isNotEmpty) {
      candidates.add('${uriBase.scheme}://${uriBase.host}:8080');
    }

    candidates.add('http://localhost:8080');
    candidates.add('http://127.0.0.1:8080');

    for (final base in candidates.toSet()) {
      try {
        final response = await http
            .get(Uri.parse('$base/health'))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          _cachedWebProxyBaseUrl = base;
          return base;
        }
      } catch (_) {}
    }

    _cachedWebProxyBaseUrl =
        _webProxyFromEnv.trim().isNotEmpty ? _webProxyFromEnv.trim() : 'http://localhost:8080';
    return _cachedWebProxyBaseUrl!;
  }

  static Future<Uri> _authEndpoint(String path) async {
    final baseUrl = kIsWeb ? '${await _resolveWebProxyBaseUrl()}/proxy/auth' : _authUrl;
    return Uri.parse('$baseUrl$path');
  }

  static Future<Uri> _iaEndpoint(String path) async {
    final baseUrl = kIsWeb ? '${await _resolveWebProxyBaseUrl()}/proxy/ia' : _iaUrl;
    return Uri.parse('$baseUrl$path');
  }

  static dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  /// 🔑 EXTRAÇÃO HIGIENIZADA DE TOKEN (Evita erro de token inválido na IA)
  static String? _extractToken(dynamic data) {
    if (data == null) return null;
    
    String? bruto;
    if (data is Map<String, dynamic>) {
      // Verifica se o token está aninhado ou direto
      final possivelToken = data['token'] ?? data['access_token'] ?? data['data']?['token'];
      if (possivelToken is Map) {
        bruto = possivelToken['token']?.toString() ?? possivelToken['access_token']?.toString();
      } else {
        bruto = possivelToken?.toString();
      }
    } else if (data is String) {
      final parsed = _tryDecodeJson(data);
      if (parsed is Map<String, dynamic>) return _extractToken(parsed);
    }

    if (bruto == null) return null;

    // Remove aspas extras, espaços ou quebras de linha que invalidam o Header HTTP Bearer
    return bruto.trim().replaceAll('"', '').replaceAll("'", "");
  }

  static String? get token => _token;
  static String get sistemaId => _sistemaId;

  static void setToken(String? novoToken) {
    if (novoToken != null) {
      _token = novoToken.trim().replaceAll('"', '').replaceAll("'", "");
    } else {
      _token = null;
    }
  }

  /// 🔐 DECODIFICADOR JWT COM SEPARAÇÃO DE NOME E SOBRENOME CORRETA
  static Map<String, dynamic> extrairDadosDoToken(String jwtToken) {
    try {
      final partes = jwtToken.split('.');
      if (partes.length < 2) return {};

      String payloadNormalizado = partes[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payloadNormalizado.length % 4) {
        case 2: payloadNormalizado += '=='; break;
        case 3: payloadNormalizado += '='; break;
      }

      final String payloadDecodificado = utf8.decode(base64Url.decode(payloadNormalizado));
      final Map<String, dynamic> dadosDoToken = jsonDecode(payloadDecodificado);

      // Pega o nome vindo do servidor
      String fullName = (dadosDoToken['name'] ?? dadosDoToken['given_name'] ?? dadosDoToken['nome'] ?? 'Usuario').toString().trim();
      String tokenSobrenome = (dadosDoToken['family_name'] ?? dadosDoToken['surname'] ?? dadosDoToken['sobrenome'] ?? '').toString().trim();

      String nomeFinal = fullName;
      String sobrenomeFinal = tokenSobrenome;

      // 🛠️ CORREÇÃO DO NOME DUPLICADO: Se o sobrenome já estiver contido dentro do campo Name, 
      // nós separamos de forma inteligente para não duplicar no banco de dados.
      if (tokenSobrenome.isEmpty && fullName.contains(' ')) {
        final partesNome = fullName.split(' ');
        nomeFinal = partesNome.first;
        sobrenomeFinal = partesNome.sublist(1).join(' ');
      }

      return {
        'nome': nomeFinal,
        'sobrenome': sobrenomeFinal,
        'email': dadosDoToken['email'] ?? dadosDoToken['user_email'],
        'login': dadosDoToken['preferred_username'] ?? dadosDoToken['sub'] ?? dadosDoToken['login'],
      };
    } catch (e) {
      debugPrint('⚠️ [JWT DECODER] Falha ao ler metadados do token: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>?> registrar({
    required String nome,
    required String sobrenome,
    required String login,
    required String email,
    required String senha,
    String sistemaId = '',
  }) async {
    try {
      final response = await http.post(
        await _authEndpoint('/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nome,
          'surname': sobrenome,
          'login': login,
          'email': email,
          'password': senha,
          'sistemaId': sistemaId.isNotEmpty ? sistemaId : _sistemaId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = _tryDecodeJson(response.body);
        _token = _extractToken(decoded) ?? _token;

        return {
          'success': true,
          'data': decoded ?? response.body,
          'token': _token,
        };
      }

      final errorBody = _tryDecodeJson(response.body);
      return {
        'success': false,
        'message': errorBody is Map<String, dynamic> ? (errorBody['message']?.toString() ?? 'Erro no registro') : 'Erro no registro',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> login({
    required String username,
    required String senha,
    String sistemaId = '',
  }) async {
    try {
      final response = await http.post(
        await _authEndpoint('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': senha,
          'sistemaId': sistemaId.isNotEmpty ? sistemaId : _sistemaId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body);
        _token = _extractToken(decoded);

        debugPrint('🔑 [API SERVICE] Token extraído e pronto: $_token');

        return {
          'success': true,
          'data': decoded ?? response.body,
          'token': _token,
        };
      }

      final errorBody = _tryDecodeJson(response.body);
      return {
        'success': false,
        'message': errorBody is Map<String, dynamic> ? (errorBody['message']?.toString() ?? 'Credenciais inválidas') : 'Credenciais inválidas',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> enviarPromptIa({
    required String prompt,
    List<Map<String, dynamic>>? history,
    String? titulo,
  }) async {
    if (_token == null || _token!.isEmpty) {
      debugPrint('❌ [IA] Tentativa de envio sem token configurado na memória do ApiService.');
      return {
        'success': false,
        'message': 'Token não disponível. Faça login novamente.',
      };
    }

    try {
      debugPrint('📡 [IA] Enviando prompt. Token utilizado (Bearer): ${_token!.substring(0, 15)}...');
      
      final response = await http.post(
        await _iaEndpoint('/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token', // Envio limpo e higienizado
        },
        body: jsonEncode({
          'prompt': prompt,
          if (history != null) 'history': history,
          if (titulo != null) 'titulo': titulo,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'data': json,
        };
      } else {
        debugPrint('❌ [IA] Erro do servidor HTTP ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Erro ao processar a requisição na IA',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na requisição da IA: ${e.toString()}',
      };
    }
  }
}