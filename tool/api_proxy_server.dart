import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String _authBaseUrl = 'https://mobile-ios-login.zani0x03.eti.br/api';
const String _iaBaseUrl = 'https://mobile-ios-ia.zani0x03.eti.br/api';

Future<void> main(List<String> args) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  stdout.writeln('Scriba API proxy running at http://localhost:8080');

  await for (final request in server) {
    unawaited(_handleRequest(request));
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  _applyCorsHeaders(request.response);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  if (request.uri.path == '/health') {
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'status': 'ok'}));
    await request.response.close();
    return;
  }

  final targetUri = _resolveTargetUri(request.uri);
  if (targetUri == null) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'message': 'Endpoint nao encontrado'}));
    await request.response.close();
    return;
  }

  final client = HttpClient();
  try {
    final upstreamRequest = await client.openUrl(request.method, targetUri);

    request.headers.forEach((name, values) {
      final lowerName = name.toLowerCase();
      if (_skipRequestHeader(lowerName)) {
        return;
      }
      for (final value in values) {
        upstreamRequest.headers.add(name, value, preserveHeaderCase: true);
      }
    });

    await upstreamRequest.addStream(request);
    final upstreamResponse = await upstreamRequest.close();

    request.response.statusCode = upstreamResponse.statusCode;
    upstreamResponse.headers.forEach((name, values) {
      final lowerName = name.toLowerCase();
      if (_skipResponseHeader(lowerName)) {
        return;
      }
      for (final value in values) {
        request.response.headers.add(name, value, preserveHeaderCase: true);
      }
    });

    await upstreamResponse.pipe(request.response);
  } catch (error) {
    request.response.statusCode = HttpStatus.badGateway;
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode({
        'message': 'Falha ao encaminhar requisicao',
        'error': error.toString(),
      }),
    );
    await request.response.close();
  } finally {
    client.close(force: true);
  }
}

Uri? _resolveTargetUri(Uri incomingUri) {
  final path = incomingUri.path;
  const proxyPrefix = '/proxy';
  const apiPrefix = '/api';

  String normalizeSuffix() {
    if (path.startsWith(proxyPrefix)) {
      return path.substring(proxyPrefix.length);
    }
    if (path.startsWith(apiPrefix)) {
      return path.substring(apiPrefix.length);
    }
    return path;
  }

  final suffix = normalizeSuffix();
  if (suffix.isEmpty) {
    return null;
  }

  if (suffix.startsWith('/auth') || suffix.startsWith('/register')) {
    final target = '$_authBaseUrl$suffix';
    stdout.writeln('Proxy route auth/register: $path -> $target');
    return Uri.parse(target).replace(
      queryParameters: incomingUri.queryParameters.isEmpty
          ? null
          : incomingUri.queryParameters,
    );
  }

  if (suffix.startsWith('/ia') || suffix.startsWith('/ai')) {
    final target = '$_iaBaseUrl$suffix';
    stdout.writeln('Proxy route ia: $path -> $target');
    return Uri.parse(target).replace(
      queryParameters: incomingUri.queryParameters.isEmpty
          ? null
          : incomingUri.queryParameters,
    );
  }

  stdout.writeln('Proxy route not found: $path');
  return null;
}

void _applyCorsHeaders(HttpResponse response) {
  response.headers.set(HttpHeaders.accessControlAllowOriginHeader, '*');
  response.headers.set(
    HttpHeaders.accessControlAllowMethodsHeader,
    'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  );
  response.headers.set(
    HttpHeaders.accessControlAllowHeadersHeader,
    'Content-Type, Authorization, Accept, Origin, X-Requested-With',
  );
  response.headers.set(
    HttpHeaders.accessControlExposeHeadersHeader,
    'Content-Type, Authorization',
  );
}

bool _skipRequestHeader(String headerName) {
  return headerName == HttpHeaders.hostHeader ||
      headerName == HttpHeaders.contentLengthHeader ||
      headerName == HttpHeaders.connectionHeader ||
      headerName == HttpHeaders.acceptEncodingHeader ||
      headerName == 'origin';
}

bool _skipResponseHeader(String headerName) {
  return headerName == HttpHeaders.contentLengthHeader ||
      headerName == HttpHeaders.connectionHeader ||
      headerName == HttpHeaders.transferEncodingHeader ||
      headerName == HttpHeaders.contentEncodingHeader;
}
