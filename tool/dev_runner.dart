import 'dart:async';
import 'dart:io';

const int proxyPort = 8080;

Future<void> main(List<String> args) async {
  String alvoInput = args.isNotEmpty ? args[0] : 'chrome';
  
  print('🚀 Scriba Dev Runner - Initializing...');

  Process? proxyProcess;
  Process? flutterProcess;

  ProcessSignal.sigint.watch().listen((_) async {
    print('\n\n🛑 Shutting down gracefully...');
    await _cleanup(proxyProcess, flutterProcess);
    exit(0);
  });

  try {
    await _killExistingProxy();

    String dispositivoFinal = alvoInput;
    
    if (alvoInput.toLowerCase() == 'mobile' || alvoInput.toLowerCase() == 'android') {
      print('🔍 Searching for connected mobile devices...');
      String? idDetectado = await _buscarIdDispositivoMobile();
      
      if (idDetectado != null) {
        dispositivoFinal = idDetectado;
        print('📱 Device auto-detected: [$dispositivoFinal]');
        
        // 🔥 NOVO: Redireciona a porta 8080 do celular para o PC via USB de forma genérica
        print('🔌 Linking device port 8080 to PC via USB...');
        await Process.run('adb', ['-s', dispositivoFinal, 'forward', 'tcp:8080', 'tcp:8080'], runInShell: true);
      } else {
        print('⚠ No physical mobile device or emulator detected. Falling back to input: [$alvoInput]');
      }
    }

    print('📡 Starting proxy on port $proxyPort...');
    print('🌐 Starting Flutter on device: $dispositivoFinal...');
    
    final proxyFuture = _startProxy();
    final flutterFuture = _startFlutter(dispositivoFinal);

    proxyProcess = await proxyFuture;
    flutterProcess = await flutterFuture;

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

/// Executa 'flutter devices' em background e captura o ID do primeiro dispositivo mobile real
Future<String?> _buscarIdDispositivoMobile() async {
  try {
    final result = await Process.run('flutter', ['devices'], runInShell: true);
    if (result.exitCode == 0) {
      String stdoutOriginal = result.stdout.toString();
      
      // CORREÇÃO DO ENCODING: Substitui o ponto bugado "â€¢" ou o ponto normal "•" por um caractere seguro "|"
      stdoutOriginal = stdoutOriginal.replaceAll('â€¢', '|').replaceAll('•', '|');

      // Limpa quebras de linha do Windows
      final linhas = stdoutOriginal.replaceAll('\r', '').split('\n');
      
      for (var linha in linhas) {
        if (linha.contains('(mobile)')) {
          final partes = linha.split('|');
          if (partes.length > 1) {
            final idDispositivo = partes[1].trim();
            if (idDispositivo.isNotEmpty) {
              return idDispositivo;
            }
          }
        }
      }
    }
  } catch (e) {
    print('⚠ Error during device auto-detection: $e');
  }
  return null;
}

Future<String> _descobrirIpLocal() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    print('\n--- DEBUG: IPs Encontrados no Computador ---');
    for (var interface in interfaces) {
      for (var endereco in interface.addresses) {
        print('Placa: [${interface.name}] -> IP: ${endereco.address}');
      }
    }
    print('-------------------------------------------\n');

    // Tenta buscar o IP do Wi-Fi primeiro (geralmente contém "wi-fi" ou "wlan" no nome)
    for (var interface in interfaces) {
      final nome = interface.name.toLowerCase();
      if (nome.contains('wi-fi') || nome.contains('wlan') || nome.contains('wireless')) {
        for (var endereco in interface.addresses) {
          return endereco.address;
        }
      }
    }

    // Filtro secundário padrão
    for (var interface in interfaces) {
      for (var endereco in interface.addresses) {
        if (endereco.address.startsWith('192.168.') || endereco.address.startsWith('10.')) {
          return endereco.address;
        }
      }
    }
    
    if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
      return interfaces.first.addresses.first.address;
    }
  } catch (e) {
    print('⚠ Could not auto-detect local IP: $e');
  }
  return 'localhost';
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

Future<Process> _startFlutter(String dispositivo) async {
  final dispositivoLower = dispositivo.toLowerCase();

  bool ehAndroid = dispositivoLower == 'android' || 
                   dispositivoLower == 'mobile' || 
                   dispositivoLower.startsWith('emulator-') ||
                   RegExp(r'^[a-zA-Z0-9_-]{6,}$').hasMatch(dispositivo);

  bool ehWeb = dispositivoLower == 'chrome' || 
               dispositivoLower == 'edge' || 
               dispositivoLower == 'web-server';

  String proxyBaseUrl = 'http://localhost:8080';
  
  if (ehAndroid) {
    if (dispositivoLower.startsWith('emulator-')) {
      proxyBaseUrl = 'http://10.0.2.2:8080'; 
    } else {
      // 🔥 AUTOMAÇÃO: Descobre o IP da sua rede sem precisar digitar nada!
      String ipDinamico = await _descobrirIpLocal();
      print('🌐 Network IP auto-detected for mobile connection: [$ipDinamico]');
      proxyBaseUrl = 'http://$ipDinamico:8080';
    }
  }

  List<String> flutterArgs = [
    'run',
    '-d',
    dispositivo,
    '--dart-define=SCRIBA_PROXY_BASE_URL=$proxyBaseUrl',
  ];

  if (ehWeb) {
    flutterArgs.add('--web-port=5000');
  }

  final process = await Process.start(
    'flutter',
    flutterArgs,
    runInShell: true, 
    mode: ProcessStartMode.inheritStdio,
  );

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