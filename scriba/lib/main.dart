import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'cadastro.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
    
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
    );


  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, // remove a faixa de debug
    home: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, 
        statusBarBrightness: Brightness.light,
      ),

// -------------------------------------------------------------------

      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/inicial.png',
                    width: 400,
                    fit: BoxFit.cover,
                  ),
                  
                  const SizedBox(height: 20),
                  
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
                  
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 60),
                            backgroundColor: const Color.fromARGB(255, 4, 51, 46),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color.fromARGB(255, 1, 30, 27), width: 1),                          
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CadastroTela()),
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
                            backgroundColor: const Color.fromARGB(255, 49, 168, 156),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color.fromARGB(255, 28, 125, 115), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginTela()),
                            );
                          },
                          child: const Text('LOGIN'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
