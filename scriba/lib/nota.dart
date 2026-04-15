import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotaTela extends StatefulWidget {
  const NotaTela({super.key, required this.textoNota});

  final String textoNota;

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
    _tituloController = TextEditingController(text: "");
    _conteudoController = TextEditingController(text: widget.textoNota);
    _conteudoFocusNode = FocusNode();
    _historicoUndo.add(widget.textoNota);

    _conteudoController.addListener(() {
      if (!_bloquearListener) {
        final novoTexto = _conteudoController.text;
        if (_historicoUndo.isEmpty || _historicoUndo.last != novoTexto) {
          setState(() {
            _historicoUndo.add(novoTexto);
            _historicoRedo.clear();
          });
        }
      }
    });
  }

  // Isso força a barra a aparecer sempre que você entrar ou voltar para esta tela
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    _conteudoFocusNode.dispose();
    super.dispose();
  }

  void _desfazer() {
    if (_historicoUndo.length > 1) {
      setState(() {
        _bloquearListener = true;
        String atual = _historicoUndo.removeLast();
        _historicoRedo.add(atual);
        _conteudoController.text = _historicoUndo.last;
        _posicionarCursorNoFinal();
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
        _posicionarCursorNoFinal();
        _bloquearListener = false;
      });
    }
  }

  void _posicionarCursorNoFinal() {
    _conteudoController.selection = TextSelection.fromPosition(
      TextPosition(offset: _conteudoController.text.length),
    );
  }

  void _voltarESalvar() {
    String titulo = _tituloController.text.trim();
    String conteudo = _conteudoController.text.trim();
    if (titulo.isEmpty) titulo = "Título da nota";
    if (conteudo.isNotEmpty) {
      Navigator.pop(context, {'titulo': titulo, 'conteudo': conteudo});
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o AnnotatedRegion para forçar o estilo da barra de status no nível do widget
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Ícones pretos
        statusBarBrightness: Brightness.light, // iOS
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          // O SafeArea é essencial para não sobrepor a barra de notificações
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
                          onPressed: _voltarESalvar,
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
                      IconButton(
                        icon: const Icon(Icons.keyboard, color: Colors.white),
                        onPressed: () {
                          _conteudoFocusNode.requestFocus();
                          SystemChannels.textInput.invokeMethod('TextInput.show');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {}),
                      IconButton(
                        icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
                        onPressed: () {
                          _conteudoController.clear();
                        }),
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