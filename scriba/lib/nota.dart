import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat.dart';

class NotaTela extends StatefulWidget {
  const NotaTela({super.key, required this.textoNota, required this.tituloNota});

  final String textoNota;
  final String tituloNota;

  @override
  State<NotaTela> createState() => _NotaTelaState();
}

class _NotaTelaState extends State<NotaTela> {
  late TextEditingController _tituloController;
  late TextEditingController _conteudoController;
  late FocusNode _conteudoFocusNode;

  List<String> _historicoUndo = [];
  List<String> _historicoRedo = [];
  bool _bloquearListener = false;

  @override
  void initState() { 
    super.initState();
    
    String tituloInicial = widget.tituloNota;
    if (tituloInicial == "Título da nota" || tituloInicial.isEmpty) {
      tituloInicial = "";
    }

    _tituloController = TextEditingController(text: tituloInicial);
    _conteudoController = TextEditingController(text: widget.textoNota);
    _conteudoFocusNode = FocusNode();
    
    _historicoUndo.add(widget.textoNota);
    _conteudoController.addListener(_escutarMudancas);
  }

  void _escutarMudancas() {
    if (!_bloquearListener) {
      final novoTexto = _conteudoController.text;
      if (_historicoUndo.isEmpty || _historicoUndo.last != novoTexto) {
        setState(() {
          _historicoUndo.add(novoTexto);
          _historicoRedo.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    _conteudoFocusNode.dispose();
    super.dispose();
  }

  void _voltarESalvar() {
    String titulo = _tituloController.text.trim();
    String conteudo = _conteudoController.text.trim();
    if (titulo.isEmpty && conteudo.isNotEmpty) titulo = "Título da nota";
    
    if (conteudo.isNotEmpty || titulo.isNotEmpty) {
      Navigator.pop(context, {'titulo': titulo, 'conteudo': conteudo});
    } else {
      Navigator.pop(context);
    }
  }

  void _desfazer() {
    if (_historicoUndo.length > 1) {
      setState(() {
        _bloquearListener = true; 
        String atual = _historicoUndo.removeLast();
        _historicoRedo.add(atual);
        
        _conteudoController.text = _historicoUndo.last;
        _conteudoController.selection = TextSelection.fromPosition(
          TextPosition(offset: _conteudoController.text.length),
        );
        _bloquearListener = false;
      });
    }
  }

  void _refazer() {
    if (_historicoRedo.isNotEmpty) {
      setState(() {
        _bloquearListener = true;
        String recuperado = _historicoRedo.removeLast();
        _historicoUndo.add(recuperado);
        
        _conteudoController.text = recuperado;
        _conteudoController.selection = TextSelection.fromPosition(
          TextPosition(offset: _conteudoController.text.length),
        );
        _bloquearListener = false;
      });
    }
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir nota?"),
        content: const Text("Essa ação removerá a nota permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {'excluir': true});
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _simularImportacaoArquivo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Importar Arquivo"),
        content: const Text("Selecione um arquivo .txt ou .md para importar o conteúdo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Buscando arquivos... (Em desenvolvimento)")),
              );
            },
            child: const Text("Selecionar"),
          ),
        ],
      ),
    );
  }

// -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, //barra transparente
        statusBarIconBrightness: Brightness.dark, // icones pretos 
        statusBarBrightness: Brightness.light,    
        //systemNavigationBarColor: Colors.white,   // barra de botões inferior
        //systemNavigationBarIconBrightness: Brightness.dark,
      ),


      child: Scaffold(
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
                          icon: const Icon(Icons.arrow_circle_left_outlined, color: Colors.grey, size: 30),
                          onPressed: _voltarESalvar,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _tituloController,
                            decoration: const InputDecoration(
                              hintText: "Título da nota",
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.black54),
                          onPressed: _simularImportacaoArquivo,
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.black54),
                          onSelected: (value) {
                            switch (value) {
                              case 'chat':
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatTela(
                                  textoNota: _conteudoController.text,
                                  tituloNota: _tituloController.text,
                                )));
                                break;
                              case 'copiar':
                                Clipboard.setData(ClipboardData(text: _conteudoController.text));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Texto copiado!")));
                                break;
                              case 'excluir':
                                _confirmarExclusao();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'chat',
                              child: ListTile(
                                leading: Icon(Icons.add_comment_outlined, color: Colors.blueAccent, size: 20),
                                title: Text("Conversar com Chat"),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copiar',
                              child: ListTile(
                                leading: Icon(Icons.copy, size: 20),
                                title: Text("Copiar tudo"),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'excluir',
                              child: ListTile(
                                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                                title: Text("Excluir nota", style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.black45, thickness: 1, indent: 10, endIndent: 10),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _conteudoController,
                    focusNode: _conteudoFocusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
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
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard, color: Colors.white),
                        onPressed: () => _conteudoFocusNode.requestFocus(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _conteudoFocusNode.requestFocus(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
                        onPressed: () {
                          setState(() {
                             _conteudoController.clear();
                          });
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.undo, color: _historicoUndo.length > 1 ? Colors.white : Colors.white24),
                        onPressed: _historicoUndo.length > 1 ? _desfazer : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.redo, color: _historicoRedo.isNotEmpty ? Colors.white : Colors.white24),
                        onPressed: _historicoRedo.isNotEmpty ? _refazer : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}