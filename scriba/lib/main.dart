import 'package:flutter/material.dart';

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

class LoginTela extends StatelessWidget {
  const LoginTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Login',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
             'Digite seus dados para acessar suas notas novamente',            
             style: TextStyle(
              fontSize: 14,
             ), 
            ),

            const SizedBox(height: 200),

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
                   
                    },
                    child: const Text('FAZER LOGIN'),
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


//// Cadastro
///

class CadastroTela extends StatelessWidget {
  const CadastroTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                onPressed: () {},
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


///Home
///

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

              },
            ),
            const Divider(), 

            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('Chat'),
              onTap: () {

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

        }, 
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
    
  }
}


///Chat
///
class ChatTela extends StatelessWidget {
  const ChatTela({super.key});

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF31A89C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Chat",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                children: [
                  buildUserBubble("Olá! Como posso começar?"),
                  const SizedBox(height: 20),
                  buildIABubble("Olá! Você pode digitar qualquer pergunta sobre suas notas ou pedir para eu criar uma nova ideia aqui."),
                ],
              ),
            ),
            buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 50), 
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[200], 
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget buildIABubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 50), 
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Color(0xFF31A89C), 
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pergunte, busque ou crie qualquer coisa...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.flash_on, color: Color(0xFF31A89C)), 
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF31A89C)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF31A89C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

///Nota
///

class NotaTela extends StatelessWidget {
  const NotaTela({super.key});

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_circle_left, color: Colors.grey, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Título da nota",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.black54),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.black54),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const Divider(color: Colors.black45, thickness: 1, indent: 10, endIndent: 10),
                  ],
                ),
              ),

              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    maxLines: null, 
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: "Comece a escrever...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF04332E), 
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.keyboard, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white), onPressed: () {}),
                      const Spacer(), 
                      IconButton(icon: const Icon(Icons.undo, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.redo, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }