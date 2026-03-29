import 'package:flutter/material.dart';
import 'chat.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),          
          children: [
            SearchBar(
              hintText: "Pesquisar..."
            ),
            const SizedBox(height: 20,),  

            ElevatedButton(
              onPressed: () {

            }, 
            child: const Text('+')
            ),
            const SizedBox(height: 20,),  

          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
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