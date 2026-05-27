import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('🔐 [TEST] Fazendo login...\n');

  try {
    // 1. Login para obter token
    final client = HttpClient();
    
    final loginUri = Uri.parse('https://mobile-ios-login.zani0x03.eti.br/api/auth/login');
    final loginRequest = await client.postUrl(loginUri);
    
    loginRequest.headers.contentType = ContentType.json;
    
    final credentials = {
      'username': 'isaias1',
      'password': 'isaias1',
      'sistemaId': '64b511cc-1392-4d37-85af-9c581961de40'
    };
    
    loginRequest.write(jsonEncode(credentials));
    
    final loginResponse = await loginRequest.close();
    final loginBody = await utf8.decodeStream(loginResponse);
    
    if (loginResponse.statusCode != 200) {
      print('❌ Erro no login (status ${loginResponse.statusCode})');
      print('Response: $loginBody');
      return;
    }
    
    final loginData = jsonDecode(loginBody) as Map<String, dynamic>;
    final token = loginData['access_token'] as String?;
    
    if (token == null) {
      print('❌ Token não obtido na resposta de login');
      print('Response: $loginData');
      return;
    }
    
    print('✅ Login bem-sucedido!');
    print('📍 Token obtido: ${token.substring(0, 50)}...\n');
    
    // 2. Testar requisição para IA
    print('🤖 [TEST] Enviando requisição para IA...\n');
    
    final prompt = 'Oi, qual é 1 + 1?';
    final iaPayload = {
      'prompt': prompt,
      'history': [
        {'role': 'user', 'content': 'Olá'}
      ],
      'titulo': 'Teste'
    };
    
    final iaUri = Uri.parse('https://mobile-ios-ia.zani0x03.eti.br/api/ai/chat');
    final iaRequest = await client.postUrl(iaUri);
    
    iaRequest.headers.contentType = ContentType.json;
    iaRequest.headers.add('Authorization', 'Bearer $token');
    
    print('📤 Enviando: $prompt');
    print('⏱️  Timeout: 5 minutos (300 segundos)\n');
    
    final startTime = DateTime.now();
    iaRequest.write(jsonEncode(iaPayload));
    
    final iaResponse = await iaRequest.close().timeout(
      const Duration(seconds: 300),
      onTimeout: () {
        throw Exception('Timeout na requisição (300s / 5min)');
      }
    );
    
    final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
    print('⏱️  Tempo de resposta: ${elapsedMs}ms (${(elapsedMs / 1000).toStringAsFixed(2)}s)\n');
    
    if (iaResponse.statusCode != 200) {
      print('❌ Erro na requisição (status ${iaResponse.statusCode})');
      final errorBody = await utf8.decodeStream(iaResponse);
      print('Response: $errorBody');
      return;
    }
    
    final iaBody = await utf8.decodeStream(iaResponse);
    final iaData = jsonDecode(iaBody) as Map<String, dynamic>;
    
    print('✅ Resposta recebida!');
    print('📦 Response completo:');
    print(jsonEncode(iaData));
    
    // Extrair resposta
    final possibleFields = ['message', 'response', 'answer', 'text', 'resultado'];
    String? answer;
    
    for (final field in possibleFields) {
      if (iaData[field] != null) {
        answer = iaData[field].toString();
        break;
      }
    }
    
    if (answer != null && answer.isNotEmpty) {
      print('\n💬 Resposta da IA:');
      print('"$answer"');
    } else {
      print('\n⚠️  Nenhuma resposta encontrada nos campos esperados');
      print('Campos disponíveis: ${iaData.keys.toList()}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erro: ${e.toString()}');
    if (e.toString().contains('SocketException')) {
      print('⚠️  Erro de conexão - verifique a URL ou sua conexão de internet');
    }
  }
}
