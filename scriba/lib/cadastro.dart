import 'package:flutter/material.dart';


class CadastroTela extends StatelessWidget {
  const CadastroTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 222, 217),      
      appBar: AppBar(title: const Text("Cadastro"),
      backgroundColor: const Color.fromARGB(255, 230, 222, 217),),
      body: Center(
        child: ListView(
          shrinkWrap: true, 
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            TextField(  
              decoration: InputDecoration(labelText: 'Nome')
            ),

            const SizedBox(height: 20,),

            TextField(  
              decoration: InputDecoration(labelText: 'E-mail')
            ),

            const SizedBox(height: 20,),   

            TextField(  
              decoration: InputDecoration(labelText: 'Senha')              
            ),

            const SizedBox(height: 20,),            
            

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 43, 78), 
                foregroundColor: Colors.white, 
              ),              
              onPressed: () {

                  },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}