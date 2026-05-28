import 'dart:async';
import 'dart:io';

const int proxyPort = 8080;

Future<void> main(List<String> args) async {
  // ALTERAÇÃO: Descobre o dispositivo alvo. Se não passar nada, o padrão é 'chrome'
  String dispositivo = args.isNotEmpty ? args[0].toLowerCase() : 'chrome';

  print('🚀 Scriba Dev Runner - Starting for target: [$dispositivo]...\n');

  Process? proxyProcess;
  Process? flutterProcess;

  // Handle Ctrl+C for graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\n\n🛑 Shutting down gracefully...');
    await _cleanup(proxyProcess, flutterProcess);
    exit(0);
  });

  try {
    // Kill any existing process on port 8080
    await _killExistingProxy();

    // Start proxy and Flutter in parallel
    print('📡 Starting proxy on port $proxyPort...');
    print('🌐 Starting Flutter on device: $dispositivo...');
    
    final proxyFuture = _startProxy();
    
    // ALTERAÇÃO: Passando o dispositivo escolhido para a função do Flutter
    final flutterFuture = _startFlutter(dispositivo);

    proxyProcess = await proxyFuture;
    flutterProcess = await flutterFuture;

    // Wait for both processes to complete
    await Future.wait([
      proxyProcess.exitCode,
      flutterProcess.exitCode,
    ]);
  } catch (e) {
    print('❌ Error: $e');
    await _cleanup(proxyProcess, flutterProcess);
    exit(1);
  }
}

Future<void> _killExistingProxy() async {
  try {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      r'Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }',
    ]);
    if (result.exitCode == 0) {
      print('✓ Freed port 8080');
    }
  } catch (e) {
    print('⚠ Could not kill existing proxy: $e');
  }
  await Future.delayed(const Duration(milliseconds: 500));
}

Future<Process> _startProxy() async {
  final process = await Process.start(
    'dart',
    ['run', 'tool/api_proxy_server.dart'],
    mode: ProcessStartMode.inheritStdio,
  );

  return process;
}

// ALTERAÇÃO: A função agora é genérica e aceita qualquer dispositivo configurado
Future<Process> _startFlutter(String dispositivo) async {
  // Se for emulador android, usa o IP especial 10.0.2.2, caso contrário usa localhost
  String proxyBaseUrl = (dispositivo == 'android') 
      ? 'http://10.0.2.2:8080' 
      : 'http://localhost:8080';

  // Configura os argumentos base do comando 'flutter run'
  List<String> flutterArgs = [
    'run',
    '-d',
    dispositivo,
    '--dart-define=SCRIBA_PROXY_BASE_URL=$proxyBaseUrl',
  ];

  // Se for um navegador de internet (chrome ou edge), mantém a porta fixa 5000
  if (dispositivo == 'chrome' || dispositivo == 'edge' || dispositivo == 'web-server') {
    flutterArgs.add('--web-port=5000');
  }

  final process = await Process.start(
    'flutter',
    flutterArgs,
    runInShell: true, 
    mode: ProcessStartMode.inheritStdio,
  );

  // Pequeno atraso para o carregamento inicial
  await Future.delayed(const Duration(seconds: 5));

  return process;
}

Future<void> _cleanup(Process? proxyProcess, Process? flutterProcess) async {
  if (proxyProcess != null && !proxyProcess.kill()) {
    print('⚠ Could not terminate proxy process');
  }
  if (flutterProcess != null && !flutterProcess.kill()) {
    print('⚠ Could not terminate Flutter process');
  }
  await Future.delayed(const Duration(milliseconds: 500));
}