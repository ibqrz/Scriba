import 'package:flutter/material.dart';
import 'package:scriba/nota.dart';
import 'chat.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.idUsuario,
    this.nomeUsuario,
  });

  final int idUsuario;
  final String? nomeUsuario;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> notas = [];
  String textoBusca = "";
  final FocusNode _focoBusca = FocusNode();

  @override
  void initState() {
    super.initState();
    _carregarNotas();
  }

  Future<void> _carregarNotas() async {
    final notasDoBanco = await DatabaseHelper.instance.getNotas(widget.idUsuario);
    if (!mounted) return;
    setState(() {
      notas = notasDoBanco;
    });
  }

  // FUNÇÃO DE NAVEGAÇÃO COM GERENCIAMENTO DE TECLADO REFORÇADO
  void _irParaTela(Widget tela) async {
    // Fecha o teclado antes de ir
    _focoBusca.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => tela),
    );

    // Garante que o teclado não "ressuscite" ao voltar para a Home
    if (mounted) {
      _focoBusca.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();

      if (resultado == true) {
        await _carregarNotas();
      }
    }
  }

  Future<void> _excluirNota(int idNota) async {
    await DatabaseHelper.instance.excluirNota(
      idNota: idNota,
      idUsuario: widget.idUsuario,
    );
    await _carregarNotas();
  }

  @override
  void dispose() {
    _focoBusca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> listaParaExibir;

    // Lógica de Filtro
    if (textoBusca.isEmpty) {
      listaParaExibir = List.from(notas);
    } else {
      listaParaExibir = notas.where((nota) {
        final String tituloOriginal = (nota['titulo'] ?? "").toString().trim();
        final String tituloParaBusca = tituloOriginal.isEmpty ? "título da nota" : tituloOriginal.toLowerCase();
        return tituloParaBusca.contains(textoBusca.toLowerCase());
      }).toList();

      if (listaParaExibir.isEmpty) {
        listaParaExibir = List.from(notas);
      } else {
        listaParaExibir.sort((a, b) {
          final String tA = (a['titulo'] ?? "").toString().trim().isEmpty ? "título da nota" : a['titulo'].toString().toLowerCase();
          final String tB = (b['titulo'] ?? "").toString().trim().isEmpty ? "título da nota" : b['titulo'].toString().toLowerCase();
          return tA.compareTo(tB);
        });
      }
    }

    bool pesquisaSemResultado = textoBusca.isNotEmpty &&
        !notas.any((nota) {
          final String t = (nota['titulo'] ?? "").toString().trim().isEmpty ? "título da nota" : nota['titulo'].toString().toLowerCase();
          return t.contains(textoBusca.toLowerCase());
        });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Fecha o teclado automaticamente ao abrir o menu lateral
      onDrawerChanged: (isOpened) {
        if (isOpened) FocusManager.instance.primaryFocus?.unfocus();
      },
      drawer: Drawer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.add_comment_outlined),
                        title: const Text('Chat'),
                        onTap: () {
                          _irParaTela(const ChatTela(textoNota: "", tituloNota: "Chat Geral"));
                        },
                      ),
                      const Spacer(),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_circle, color: Colors.grey, size: 40),
                            const SizedBox(height: 5),
                            Text(
                              widget.nomeUsuario ?? "Usuário",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            icon: const Icon(Icons.logout),
                            label: const Text("SAIR", style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 168, 156),
        foregroundColor: Colors.white,
        title: const Text(
          "Home",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 30),
            SearchBar(
              focusNode: _focoBusca,
              hintText: "Procurar nota...",
              onChanged: (valor) {
                setState(() {
                  textoBusca = valor;
                });
              },
              // Fecha o teclado ao clicar na lupa/pesquisar do teclado
              onSubmitted: (valor) {
                _focoBusca.unfocus();
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
              onPressed: () => _irParaTela(NotaTela(textoNota: "", tituloNota: "", notaId: null, idUsuario: widget.idUsuario)),
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
                      width: 300, errorBuilder: (context, error, stackTrace) => const Icon(Icons.notes, size: 100, color: Colors.grey)),
                  const Text("Nenhuma nota por aqui...", style: TextStyle(color: Colors.grey)),
                ],
              )
            else
              ...listaParaExibir.asMap().entries.map((entry) {
                int index = entry.key;
                var nota = entry.value;
                bool ultimaNota = index == listaParaExibir.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: ultimaNota ? 80 : 15),
                  child: Card(
                    elevation: 3,
                    child: ListTile(
                      title: Text((nota['titulo'] ?? "").toString().trim().isEmpty ? "Título da nota" : nota['titulo']),
                      subtitle: Text(
                        nota['conteudo'] ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _excluirNota(nota['id_nota'] as int),
                      ),
                      onTap: () async {
                        FocusManager.instance.primaryFocus?.unfocus();

                        await DatabaseHelper.instance.atualizarTimestamp(
                          nota['id_nota'] as int,
                          widget.idUsuario,
                        );

                        await _carregarNotas();

                        _irParaTela(
                          NotaTela(
                            textoNota: nota['conteudo']?.toString() ?? "",
                            tituloNota: nota['titulo']?.toString() ?? "",
                            notaId: nota['id_nota'] as int,
                            idUsuario: widget.idUsuario,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 49, 168, 156),
        foregroundColor: Colors.white,
        onPressed: () => _irParaTela(const ChatTela(textoNota: "", tituloNota: "Assistente Scriba")),
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }
}