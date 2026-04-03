import 'package:flutter/material.dart';

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