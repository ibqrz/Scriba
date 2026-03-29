import 'package:flutter/material.dart';
import 'login.dart'; 
import 'cadastro.dart';

void main() {
  runApp(const MaterialApp( // MaterialApp aqui no topo ajuda na navegação
    home: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Usamos shrinkWrap para o ListView não tentar "dominar" a tela toda
        child: ListView(
          shrinkWrap: true, 
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const Text(
              'Bem-vindo(a)!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginTela()),
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CadastroTela()),
                );
              },
              child: const Text('Cadastrar-se'),
            ),
          ],
        ),
      ),
    );
  }
}