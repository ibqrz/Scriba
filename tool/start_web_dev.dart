import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

const int proxyPort = 8080;
const Duration proxyHealthCheckInterval = Duration(milliseconds: 500);
const Duration proxyHealthCheckTimeout = Duration(seconds: 30);

Future<void> main(List<String> args) async {
  final scriptPath = File.fromUri(Platform.script).absolute.path;
  final toolDir = p.dirname(scriptPath);
  final projectRoot = p.dirname(toolDir);
  final proxyScript = p.join(projectRoot, 'tool', 'api_proxy_server.dart');

  if (!File(proxyScript).existsSync()) {
    stderr.writeln('Arquivo de proxy nao encontrado: $proxyScript');
    exit(1);
  }

  final webPortArg = _parseWebPort(args);
  final flutterArgs = [
    'run',
    '-d',
    'chrome',
    '--dart-define=SCRIBA_PROXY_BASE_URL=http://localhost:$proxyPort',
  ];
  if (webPortArg != null) {
    flutterArgs.addAll(['--web-port', webPortArg.toString()]);
  }

  final proxyProcess = await _startProxy(proxyScript);
  final shutdownCompleter = Completer<void>();

  void cleanExit(int code) async {
    if (!shutdownCompleter.isCompleted) {
      shutdownCompleter.complete();
      await _stopProcess(proxyProcess, 'proxy');
    }
    exit(code);
  }

  ProcessSignal.sigint.watch().listen((_) => cleanExit(0));
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) => cleanExit(0));
  }

  final proxyReady = await _waitForProxy();
  if (!proxyReady) {
    stderr.writeln('Proxy nao ficou pronto no tempo esperado. Verifique se a porta $proxyPort esta livre.');
    await _stopProcess(proxyProcess, 'proxy');
    exit(1);
  }

  stdout.writeln('✅ Proxy pronto em http://localhost:$proxyPort');
  stdout.writeln('🌐 Iniciando Flutter Web...');

  final flutterProcess = await _startFlutter(flutterArgs);
  await Future.any([
    flutterProcess.exitCode,
    shutdownCompleter.future,
  ]);

  await _stopProcess(flutterProcess, 'flutter');
  await _stopProcess(proxyProcess, 'proxy');
}

int? _parseWebPort(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--web-port=')) {
      return int.tryParse(arg.split('=')[1]);
    }
    if (arg == '--web-port' && i + 1 < args.length) {
      return int.tryParse(args[i + 1]);
    }
  }
  return null;
}

Future<Process> _startProxy(String proxyScript) async {
  stdout.writeln('🚀 Iniciando proxy Scriba na porta $proxyPort...');
  final process = await Process.start(
    'dart',
    ['run', proxyScript],
    runInShell: true,
  );

  process.stdout.transform(utf8.decoder).listen(stdout.write);
  process.stderr.transform(utf8.decoder).listen(stderr.write);

  return process;
}

Future<Process> _startFlutter(List<String> args) async {
  stdout.writeln('Iniciando flutter com args: ${args.join(' ')}');
  final process = await Process.start(
    'flutter',
    args,
    runInShell: true,
  );

  process.stdout.transform(utf8.decoder).listen(stdout.write);
  process.stderr.transform(utf8.decoder).listen(stderr.write);

  return process;
}

Future<bool> _waitForProxy() async {
  final uri = Uri.parse('http://localhost:$proxyPort/health');
  final deadline = DateTime.now().add(proxyHealthCheckTimeout);

  while (DateTime.now().isBefore(deadline)) {
    if (await _proxyIsHealthy(uri)) {
      return true;
    }
    await Future.delayed(proxyHealthCheckInterval);
  }

  return false;
}

Future<bool> _proxyIsHealthy(Uri uri) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 2));
    return response.statusCode == HttpStatus.ok;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

Future<void> _stopProcess(Process process, String name) async {
  stdout.writeln('🛑 Encerrando processo $name...');
  try {
    process.kill(ProcessSignal.sigterm);
  } catch (_) {
    process.kill();
  }
  try {
    await process.exitCode.timeout(const Duration(seconds: 5));
  } catch (_) {
    process.kill(ProcessSignal.sigkill);
  }
}
