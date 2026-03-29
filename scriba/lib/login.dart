import 'package:flutter/material.dart';
import 'home.dart';

class LoginTela extends StatelessWidget {
  const LoginTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [

            TextField(  
              decoration: InputDecoration(labelText: 'E-mail')
            ),

            const SizedBox(height: 20,),

            TextField(  
              decoration: InputDecoration(labelText: 'Senha') 
            ),

            const SizedBox(height: 20,),

            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}