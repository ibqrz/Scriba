import 'package:flutter/material.dart';
import 'login.dart';
import 'cadastro.dart';

void main() {
  runApp(const MaterialApp( 
    home: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          shrinkWrap: true, 
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Image.asset(
              'assets/inicial.png',
              width: 200,
              //height: 200,
              fit: BoxFit.cover,
            ),

            const Text(
              'SCRIBA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 20),        

            const Text(
              'Bem-vindo(a) ao Scriba, o seu novo refúgio para ideias, rascunhos e grandes projetos.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 20),

            Center( 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 60),
                          backgroundColor: Color.fromARGB(255, 4, 51, 46),
                          foregroundColor: Color.fromARGB(255, 255, 255, 255),
                          side: const BorderSide(color: Color.fromARGB(255, 1, 30, 27), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CadastroTela())
                          );
                        },
                        child: const Text('CADASTRO'),
                      ),
                    ),

                    const SizedBox(width: 20), 

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 60),
                          backgroundColor: Color.fromARGB(255, 49, 168, 156),
                          foregroundColor: Color.fromARGB(255, 255, 255, 255),
                          side: const BorderSide(color: Color.fromARGB(255, 28, 125, 115), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),                        
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginTela())
                          );                          
                        },
                        child: const Text('LOGIN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

//// Login
///

