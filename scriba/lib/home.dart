import 'package:flutter/material.dart';
import 'chat.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 222, 217),
      appBar: AppBar(title: const Text("Home"),       
      backgroundColor: const Color.fromARGB(255, 230, 222, 217),),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),          
          children: [
            SearchBar(
              hintText: "Pesquisar...", 
              constraints: BoxConstraints(
                maxHeight: 60,
                minHeight: 40,
              ),
            ),
            const SizedBox(height: 20,),  

            ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 43, 78), 
              foregroundColor: Colors.white, 
              ),  
              onPressed: () {

            }, 
            child: const Text('+')
            ),
            const SizedBox(height: 20,),  

          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 0, 43, 78), 
          foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatTela()),
          );
        }, 
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
    
  }
}