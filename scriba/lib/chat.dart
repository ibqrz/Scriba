import 'package:flutter/material.dart';


class ChatTela extends StatelessWidget {
  const ChatTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 222, 217),
      appBar: AppBar(title: const Text("Chat"),      
      backgroundColor: const Color.fromARGB(255, 230, 222, 217),),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Container()),

            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Digite uma mensagem",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {},
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