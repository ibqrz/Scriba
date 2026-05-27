import 'dart:async';
import 'dart:io';

const int proxyPort = 8080;
const String proxyHealthUrl = 'http://localhost:$proxyPort/health';

Future<void> main(List<String> args) async {
  print('🚀 Scriba Dev Runner - Starting...\n');

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

    // Start proxy and Flutter web in parallel
    print('📡 Starting proxy on port $proxyPort...');
    print('🌐 Starting Flutter web...');
    
    final proxyFuture = _startProxy();
    final flutterFuture = _startFlutterWeb();

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
  await Future.delayed(Duration(milliseconds: 500));
}

Future<Process> _startProxy() async {
  final process = await Process.start(
    'dart',
    ['run', 'tool/api_proxy_server.dart'],
    mode: ProcessStartMode.inheritStdio,
  );

  return process;
}



Future<Process> _startFlutterWeb() async {
  const proxyBaseUrl = 'http://localhost:8080';

  final process = await Process.start(
    'flutter',
    [
      'run',
      '-d',
      'chrome',
      '--web-port=5000', // Porta fixa para facilitar
      '--dart-define=SCRIBA_PROXY_BASE_URL=$proxyBaseUrl',
    ],
    runInShell: true, // Garante que o comando seja executado no shell do sistema
    mode: ProcessStartMode.inheritStdio,
  );

  // Adiciona um pequeno atraso para dar tempo ao Chrome de abrir
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
  await Future.delayed(Duration(milliseconds: 500));
}
