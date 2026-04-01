import 'package:flutter/material.dart';


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
      backgroundColor: const Color.fromARGB(255, 230, 222, 217),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 43, 78), 
                foregroundColor: Colors.white, 
              ),
              onPressed: () {

              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 43, 78), 
                foregroundColor: Colors.white, 
              ),
              onPressed: () {

              },
              child: const Text('Cadastrar-se'),
            ),
          ],
        ),
      ),
    );
  }
}