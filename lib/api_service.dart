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
  static const String _sistemaId = '64b511cc-1392-4d37-85af-9c581961de40'; // ID do sistema fornecido pelo professor

  static String? _token;
  static String? _cachedWebProxyBaseUrl;

  static Future<String> _resolveWebProxyBaseUrl() async {
    if (!kIsWeb) return '';
    if (_cachedWebProxyBaseUrl != null) {
      return _cachedWebProxyBaseUrl!;
    }

    final List<String> candidates = [];
    if (_webProxyFromEnv.trim().isNotEmpty) {
      candidates.add(_webProxyFromEnv.trim());
    }

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
      } catch (_) {
        // Tenta o proximo endereco automaticamente.
      }
    }

    _cachedWebProxyBaseUrl =
        _webProxyFromEnv.trim().isNotEmpty ? _webProxyFromEnv.trim() : 'http://localhost:8080';
    return _cachedWebProxyBaseUrl!;
  }

  static Future<Uri> _authEndpoint(String path) async {
    final baseUrl = kIsWeb
        ? '${await _resolveWebProxyBaseUrl()}/proxy/auth'
        : _authUrl;
    return Uri.parse('$baseUrl$path');
  }

  static Future<Uri> _iaEndpoint(String path) async {
    final baseUrl = kIsWeb
        ? '${await _resolveWebProxyBaseUrl()}/proxy/ia'
        : _iaUrl;
    return Uri.parse('$baseUrl$path');
  }

  static dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String? _extractToken(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final token = data['token'] ?? data['access_token'];
    if (token == null) return null;
    return token.toString();
  }

  // Getter para o token
  static String? get token => _token;

  // Getter para o sistemaId
  static String get sistemaId => _sistemaId;

  // Setter para o token
  static void setToken(String? novoToken) {
    _token = novoToken;
  }

  /// Registra um novo usuário
  /// Retorna um Map com os dados do usuário e o token, ou null se falhar
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
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': nome,
          'surname': sobrenome,
          'login': login,
          'email': email,
          'password': senha,
          'sistemaId': sistemaId.isNotEmpty ? sistemaId : _sistemaId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout na requisição de registro'),
      );

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
      final rawBody = response.body.trim();
      
      String message;
      if (response.statusCode == 409) {
        message = 'Este usuário (email/login) já existe. Tente com outros dados.';
      } else if (response.statusCode == 400) {
        message = errorBody is Map<String, dynamic>
          ? (errorBody['message']?.toString() ?? 'Dados inválidos. Verifique os campos.')
          : 'Dados inválidos. Verifique os campos.';
      } else {
        message = errorBody is Map<String, dynamic>
          ? (errorBody['message']?.toString() ?? 'Erro ao registrar usuario')
          : (rawBody.isNotEmpty ? rawBody : 'Erro ao registrar usuario');
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na requisição: ${e.toString()}',
      };
    }
  }

  /// Faz login de um usuário
  /// Retorna um Map com os dados do usuário e o token
  static Future<Map<String, dynamic>?> login({
    required String username,
    required String senha,
    String sistemaId = '',
  }) async {
    try {
      final response = await http.post(
        await _authEndpoint('/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': senha,
          'sistemaId': sistemaId.isNotEmpty ? sistemaId : _sistemaId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout na requisição de login'),
      );

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body);
        _token = _extractToken(decoded) ?? _token;

        return {
          'success': true,
          'data': decoded ?? response.body,
          'token': _token,
        };
      }

        final errorBody = _tryDecodeJson(response.body);
        final rawBody = response.body.trim();
        final message = errorBody is Map<String, dynamic>
          ? (errorBody['message']?.toString() ?? 'Credenciais invalidas')
          : (rawBody.isNotEmpty ? rawBody : 'Credenciais invalidas');

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na requisição: ${e.toString()}',
      };
    }
  }

  /// Envia um prompt para a IA
  /// Requer token de autenticação
  /// Agora aceita histórico e título para contexto adicional
  static Future<Map<String, dynamic>?> enviarPromptIa({
    required String prompt,
    List<Map<String, dynamic>>? history,
    String? titulo,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token não disponível. Faça login primeiro.',
      };
    }

    try {
      final response = await http.post(
        await _iaEndpoint('/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'prompt': prompt,
          if (history != null) 'history': history,
          if (titulo != null) 'titulo': titulo,
        }),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('Timeout na requisição de chat (120s)'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'data': json,
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao processar a requisição',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na requisição: ${e.toString()}',
      };
    }
  }
}
