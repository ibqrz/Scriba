import 'package:flutter/material.dart';
import 'package:scriba/nota.dart'; 
import 'chat.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> notas = [];
  String textoBusca = ""; 

  void _excluirNota(Map<String, String> notaParaExcluir) {
    setState(() {
      notas.remove(notaParaExcluir);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> notasFiltradas = notas.where((nota) {
      final titulo = (nota['titulo'] ?? "").toLowerCase();
      return titulo.contains(textoBusca.toLowerCase());
    }).toList();

    bool pesquisaSemResultado = textoBusca.isNotEmpty && notasFiltradas.isEmpty;
    List<Map<String, String>> listaParaExibir = pesquisaSemResultado ? notas : notasFiltradas;

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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCRIBA',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
              onTap: () => Navigator.pop(context),
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatTela(
                  textoNota: "", 
                  tituloNota: "Chat Geral",
                )));
              },
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.logout),
                  label: const Text("SAIR", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 168, 156),
        foregroundColor: Colors.white,
        title: const Text("Home", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 30),
          
          SearchBar(
            hintText: "Procurar nota...",
            onChanged: (valor) {
              setState(() {
                textoBusca = valor;
              });
            },
            leading: const Icon(Icons.search, color: Colors.black),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 60, minHeight: 40),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 60),
              backgroundColor: const Color.fromARGB(255, 4, 51, 46),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotaTela(
                    textoNota: "", 
                    tituloNota: "" 
                  )
                ),
              );

              if (resultado != null && resultado is Map<String, String>) {
                setState(() {
                  notas.insert(0, resultado);
                });
              }
            },
            child: const Text('NOVA NOTA'),
          ),
          const SizedBox(height: 20),

          if (pesquisaSemResultado)
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                "Nenhuma nota encontrada. Exibindo todas:",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          if (notas.isEmpty)
            Column(
              children: [
                const SizedBox(height: 50),
                Image.asset('assets/home.png', 
                  width: 300, 
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.notes, size: 100, color: Colors.grey)
                ),
                const Text("Nenhuma nota por aqui...", style: TextStyle(color: Colors.grey)),
              ],
            )
          else
            ...listaParaExibir.map((nota) {
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  title: Text(nota['titulo'] ?? "Título da nota"),
                  subtitle: Text(
                    nota['conteudo'] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _excluirNota(nota),
                  ),
                  onTap: () async {
                    final notaEditada = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotaTela(
                          textoNota: nota['conteudo'] ?? "",
                          tituloNota: nota['titulo'] ?? "", 
                        ),
                      ),
                    );

                    if (notaEditada != null && notaEditada is Map<String, String>) {
                      setState(() {
                        notas.remove(nota); 
                        notas.insert(0, notaEditada);
                      });
                    }
                  },
                ),
              );
            }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 49, 168, 156),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatTela(
            textoNota: "", 
            tituloNota: "Assistente Scriba",
          )));
        },
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }
}