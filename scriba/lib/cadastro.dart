import 'package:flutter/material.dart';
import 'package:scriba/home.dart';


class CadastroTela extends StatelessWidget {
  const CadastroTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        child: ListView(
          shrinkWrap: true, 
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          children: [

            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_circle_left_outlined, color: Colors.grey, size: 40),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Cadastro',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
             'Digite seus dados para começar a criar novas ideias',
             style: TextStyle(
              fontSize: 14,
             ), 
            ),

            const SizedBox(height: 80),

            Center(
              child: TextField(  
                decoration: InputDecoration(
                  labelText: 'Digite seu nome',
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 2.0,
                    ),
                  ),
                ),
              ),
            ),


            const SizedBox(height: 20,),

            Center(
              child: TextField(  
                decoration: InputDecoration(
                  labelText: 'Digite seu e-mail',
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 2.0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),   
          
            Center(
              child: TextField(  
                decoration: InputDecoration(
                  labelText: 'Digite sua senha',
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 2.0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),  

            Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 60),
                      backgroundColor: Color.fromARGB(255, 49, 168, 156), 
                      foregroundColor: Colors.white, 
                      side: const BorderSide(color: Color.fromARGB(255, 28, 125, 115), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),              
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    },
                    child: const Text('FAZER CADASTRO'),
                  ),                  
                ],
              ),            
            ),          
          ],
        ),
      ),
    );
  }
}