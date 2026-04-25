import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = "https://scriba-api.com";

  Future<List<dynamic>> buscarNotasRemotas(int idUsuario) async {
    final response = await http.get(Uri.parse('$baseUrl/notas/$idUsuario'));

    if (response.statusCode == 200) {
      return json.decode(response.body); // Transforma o JSON em Lista/Map
    } else {
      throw Exception('Falha ao carregar dados da API');
    }
  }
}