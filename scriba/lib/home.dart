import 'package:flutter/material.dart';
import 'package:scriba/nota.dart';
import 'chat.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 120, 
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, top: 40),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 49, 168, 156),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'SCRIBA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Suas ideias em ordem',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('Minhas Notas'),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const HomePage())
                );
              },
            ),
            const Divider(), 

            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('Chat'),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const ChatTela())
                );
              },
            ),
            const Divider(),

            const Spacer(), 

            const Divider(),

            Padding(
              padding: const EdgeInsets.only(bottom: 30.0), 
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "SAIR",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                ),
              ),
            ),
          ],
        ),
      ),


      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 49, 168, 156),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
        title: const Text(
          "Home",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        
      ),

      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),          
          children: [
            const SizedBox(height: 30 ,),

            SearchBar(
              hintText: "Procurar nota...",
              leading: const Icon(Icons.search, color: Colors.black),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: 60,
                minHeight: 40,
              ),
            ),
            const SizedBox(height: 20,),  

            ElevatedButton(
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
                Navigator.push(context, 
                MaterialPageRoute(builder: (context) => NotaTela())
              );
            }, 
            child: const Text('NOVA NOTA')
            ),
            const SizedBox(height: 20,),  

            Image.asset(
              'assets/home.png',
              width: 100,
              //height: 100,
              fit: BoxFit.cover,
            ),


          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromARGB(255, 49, 168, 156), 
          foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const ChatTela())
          );
        }, 
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
    
  }
}