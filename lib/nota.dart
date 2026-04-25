import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat.dart';
import 'database_helper.dart';

enum StatusSalvamento { inicial, salvando, salvo }

class NotaTela extends StatefulWidget {
  const NotaTela({
    super.key,
    required this.textoNota,
    required this.tituloNota,
    required this.idUsuario,
    this.notaId,
  });

  final String textoNota;
  final String tituloNota;
  final int idUsuario;
  final int? notaId;

  @override
  State<NotaTela> createState() => _NotaTelaState();
}

class _NotaTelaState extends State<NotaTela> {
  late TextEditingController _tituloController;
  late TextEditingController _conteudoController;
  late FocusNode _conteudoFocusNode;

  // logica de icons de salvamento
  StatusSalvamento _statusSalvamento = StatusSalvamento.inicial;
  Timer? _debounce;
  late String _tituloOriginal;
  late String _conteudoOriginal;

  final List<String> _historicoUndo = [];
  final List<String> _historicoRedo = [];
  bool _bloquearListener = false;

  @override
  void initState() {
    super.initState();

    _tituloOriginal = widget.tituloNota == "Título da nota" || widget.tituloNota.isEmpty 
        ? "" 
        : widget.tituloNota;
    _conteudoOriginal = widget.textoNota;

    _tituloController = TextEditingController(text: _tituloOriginal);
    _conteudoController = TextEditingController(text: _conteudoOriginal);
    _conteudoFocusNode = FocusNode();

    _historicoUndo.add(_conteudoOriginal);
    
    // monitora digitação e trocar icons de salvamento 
    _tituloController.addListener(_monitorarDigitacao);
    _conteudoController.addListener(_monitorarDigitacao);
    _conteudoController.addListener(_escutarMudancas);
  }

  void _monitorarDigitacao() {
    if (_bloquearListener) return;

    final tituloAtual = _tituloController.text;
    final conteudoAtual = _conteudoController.text;

    // ativa se o conteudo for realmente diferente do que existia ao entrar
    if (tituloAtual != _tituloOriginal || conteudoAtual != _conteudoOriginal) {
      if (_statusSalvamento != StatusSalvamento.salvando) {
        setState(() {
          _statusSalvamento = StatusSalvamento.salvando;
        });
      }

      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _statusSalvamento = StatusSalvamento.salvo;
            // atualiza referência para o icone continuar branco enquanto não houver nova digitação
            _tituloOriginal = _tituloController.text;
            _conteudoOriginal = _conteudoController.text;
          });
        }
      });
    }
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
    _debounce?.cancel();
    _tituloController.dispose();
    _conteudoController.dispose();
    _conteudoFocusNode.dispose();
    super.dispose();
  }

  // icones para a barra inferior - salvamento
  Widget _buildStatusIcon() {
    switch (_statusSalvamento) {
      case StatusSalvamento.inicial:
        return const Icon(Icons.filter_drama_sharp, color: Colors.grey);
      case StatusSalvamento.salvando:
        return const Icon(Icons.cloud_sync_outlined, color: Colors.white);
      case StatusSalvamento.salvo:
        return const Icon(Icons.filter_drama_sharp, color: Colors.white);
    }
  }

  // função para salvar os dados
  Future<void> _voltarESalvar() async {
    String titulo = _tituloController.text.trim();
    String conteudo = _conteudoController.text.trim();

    if (titulo.isEmpty && conteudo.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    if (titulo.isEmpty && conteudo.isNotEmpty) titulo = "Título da nota";

    if (widget.notaId == null) {
      await DatabaseHelper.instance.inserirNota(
        titulo: titulo,
        conteudo: conteudo,
        idUsuario: widget.idUsuario,
      );
    } else {
      await DatabaseHelper.instance.atualizarNota(
        idNota: widget.notaId!,
        idUsuario: widget.idUsuario,
        titulo: titulo,
        conteudo: conteudo,
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
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
    final rootNavigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir nota?"),
        content: const Text("Essa ação removerá a nota permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (widget.notaId != null) {
                await DatabaseHelper.instance.excluirNota(
                  idNota: widget.notaId!,
                  idUsuario: widget.idUsuario,
                );
              }
              if (!mounted) return;
              rootNavigator.pop(true);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // impede a saida direta para forçar o salvamento - barra inferior/superior do cel/nav 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // qnd usa o botão do sistema ou gesto de voltar
        await _voltarESalvar();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
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
                            icon: const Icon(Icons.get_app_rounded, color: Colors.black54),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _buildStatusIcon(),
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
                          icon: Icon(Icons.undo_rounded, color: _historicoUndo.length > 1 ? Colors.white : Colors.white24),
                          onPressed: _historicoUndo.length > 1 ? _desfazer : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.redo_rounded, color: _historicoRedo.isNotEmpty ? Colors.white : Colors.white24),
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
      ),
    );
  }
}