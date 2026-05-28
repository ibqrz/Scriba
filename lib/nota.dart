import 'dart:async';
import 'dart:typed_data'; // Importação necessária para ler os bytes no Web
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart'; 
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:scriba/chat.dart';
import 'package:scriba/repositories/note_repository.dart';

enum StatusSalvamento { inicial, salvando, salvo }

class NotaTela extends StatefulWidget {
  const NotaTela({
    super.key,
    required this.textoNota,
    required this.tituloNota,
    required this.idUsuario,
    this.notaId,
    this.nomeAnexo,
    this.caminhoAnexo,
  });

  final String textoNota;
  final String tituloNota;
  final int idUsuario;
  final int? notaId;
  final String? nomeAnexo;
  final String? caminhoAnexo;

  @override
  State<NotaTela> createState() => _NotaTelaState();
}

class _NotaTelaState extends State<NotaTela> with WidgetsBindingObserver {
  final NoteRepository _noteRepository = NoteRepository();
  late TextEditingController _tituloController;
  late TextEditingController _conteudoController;
  late FocusNode _conteudoFocusNode;
  late VoidCallback _conteudoListener;

  final List<String> _historicoUndo = [];
  final List<String> _historicoRedo = [];
  bool _bloquearListener = false;
  bool _estaCarregando = false;

  int? _notaIdAtual;
  String? _nomeArquivoAnexado;
  String? _caminhoArquivoAnexado;
  
  StatusSalvamento _statusSalvamento = StatusSalvamento.inicial;
  Timer? _debounce;
  late String _tituloOriginal;
  late String _conteudoOriginal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _notaIdAtual = widget.notaId;
    _tituloOriginal = widget.tituloNota;
    _conteudoOriginal = widget.textoNota;

    _tituloController = TextEditingController(text: _tituloOriginal);
    _conteudoController = TextEditingController(text: _conteudoOriginal);
    _conteudoFocusNode = FocusNode();

    _nomeArquivoAnexado = widget.nomeAnexo;
    _caminhoArquivoAnexado = widget.caminhoAnexo;

    _conteudoListener = () {
      if (!mounted) return;
      _escutarMudancas();
    };
    
    _historicoUndo.add(_conteudoOriginal);
    
    _tituloController.addListener(_monitorarDigitacao);
    _conteudoController.addListener(_monitorarDigitacao);
    _conteudoController.addListener(_conteudoListener);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _tituloController.dispose();
    _conteudoController.removeListener(_conteudoListener);
    _conteudoController.dispose();
    _conteudoFocusNode.dispose();
    super.dispose();
  }

  // --- Popups de Confirmação Padronizados ---
  
  void _confirmarExcluirAnexo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover anexo?"),
        content: const Text("O arquivo será desvinculado desta nota."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR", style: TextStyle(color: Color(0xFF31A89C)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF04332E)),
            onPressed: () {
              setState(() { 
                _nomeArquivoAnexado = null; 
                _caminhoArquivoAnexado = null; 
              });
              _salvarNoBanco(encerrarTela: false);
              Navigator.pop(context);
            },
            child: const Text("REMOVER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusaoNota() {
    final rootNavigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir nota?"),
        content: const Text("Essa ação removerá a nota permanentemente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR", style: TextStyle(color: Color(0xFF31A89C)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF04332E)),
            onPressed: () async {
              Navigator.pop(context); // Fecha o dialog
              if (_notaIdAtual != null) {
                await _noteRepository.excluirNota(
                  idNota: _notaIdAtual!, 
                  idUsuario: widget.idUsuario,
                );
              }
              rootNavigator.pop(true); // Sai da tela retornando true para recarregar a home
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarAnexo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Anexar Arquivo"),
        content: const Text("Deseja anexar um arquivo a esta nota?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR", style: TextStyle(color: Color(0xFF31A89C)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF04332E)),
            onPressed: () { 
              Navigator.pop(context); 
              _importarArquivoParaAnexo(); 
            },
            child: const Text("ANEXAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarImportacaoConteudo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Importar Conteúdo"),
        content: const Text("Deseja importar o texto de um arquivo para esta nota?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR", style: TextStyle(color: Color(0xFF31A89C)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF04332E)),
            onPressed: () { 
              Navigator.pop(context); 
              _importarConteudoDeArquivo(); 
            },
            child: const Text("IMPORTAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// --- Lógicas de Arquivo Adaptadas para Versões Antigas + Web ---

  Future<void> _importarArquivoParaAnexo() async {
    try {
      // Chamada direta sem o .platform para funcionar na sua versão do pacote
      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.any);
      if (result != null) {
        setState(() {
          _nomeArquivoAnexado = result.files.single.name;
          _caminhoArquivoAnexado = result.files.single.path ?? result.files.single.name;
        });
        _salvarNoBanco(encerrarTela: false);
      }
    } catch (e) { 
      debugPrint("Erro anexo: $e"); 
    }
  }

  Future<void> _importarConteudoDeArquivo() async {
    try {
      // Chamada direta sem o .platform
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md'],
      );

      if (result != null) {
        setState(() => _estaCarregando = true);
        await Future.delayed(const Duration(milliseconds: 300));

        String textoExtraido = "";
        final extensao = result.files.single.extension?.toLowerCase();
        
        // Em versões antigas do file_picker rodando na Web, os bytes ficam dentro de result.files.single.bytes
        final Uint8List? bytes = result.files.single.bytes;

        if (bytes == null) {
          throw Exception("Não foi possível ler os dados binários do arquivo. Verifique as permissões.");
        }

        if (extensao == 'pdf') {
          // O Syncfusion extrai o PDF direto dos bytes na memória
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          textoExtraido = PdfTextExtractor(document).extractText();
          document.dispose();
        } else {
          // Converte os bytes para texto puro (UTF-8) para .txt e .md
          textoExtraido = String.fromCharCodes(bytes);
        }

        if (!mounted) return;

        if (textoExtraido.trim().isNotEmpty) {
          setState(() {
            _conteudoController.text += "\n\n$textoExtraido";
            _estaCarregando = false;
          });
          _salvarNoBanco(encerrarTela: false);
        } else { 
          setState(() => _estaCarregando = false); 
        }
      }
    } catch (e) {
      debugPrint("Erro detalhado na leitura: $e");
      if (mounted) {
        setState(() => _estaCarregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao ler conteúdo do arquivo.")),
        );
      }
    }
  }
  
  Future<void> _abrirArquivoAnexo() async {
    if (_caminhoArquivoAnexado != null) await OpenFilex.open(_caminhoArquivoAnexado!);
  }

  // --- Sistema de Salvamento e Histórico ---

  void _monitorarDigitacao() {
    if (_bloquearListener) return;
    if (_tituloController.text != _tituloOriginal || _conteudoController.text != _conteudoOriginal) {
      setState(() => _statusSalvamento = StatusSalvamento.salvando);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1000), () => _salvarNoBanco(encerrarTela: false));
    }
  }

  Future<void> _salvarNoBanco({required bool encerrarTela}) async {
    debugPrint('[NOTA] _salvarNoBanco called encerrarTela=$encerrarTela notaIdAtual=$_notaIdAtual');
    String titulo = _tituloController.text.trim();
    String conteudo = _conteudoController.text.trim();
    
    if (titulo.isEmpty && conteudo.isEmpty) {
      if (encerrarTela && mounted) Navigator.pop(context, false);
      return;
    }
    if (titulo.isEmpty) titulo = "Título da nota";

    _bloquearListener = true;
    try {
      if (_notaIdAtual == null) {
        final insertedId = await _noteRepository.salvarNota(
          titulo: titulo,
          conteudo: conteudo,
          idUsuario: widget.idUsuario,
          nomeAnexo: _nomeArquivoAnexado,
          caminhoAnexo: _caminhoArquivoAnexado,
        );
        if (insertedId != 0) {
          _notaIdAtual = insertedId;
        }
      } else {
        await _noteRepository.salvarNota(
          notaId: _notaIdAtual,
          idUsuario: widget.idUsuario,
          titulo: titulo,
          conteudo: conteudo,
          nomeAnexo: _nomeArquivoAnexado,
          caminhoAnexo: _caminhoArquivoAnexado,
        );
      }

      if (mounted) {
        setState(() {
          _statusSalvamento = StatusSalvamento.salvo;
        });
      }

      if (encerrarTela && mounted) {
        debugPrint('[NOTA] salvamento concluído - pop retornando true');
        Navigator.pop(context, true);
      }
    } catch (e, st) { 
      debugPrint("Erro ao salvar nota: $e\n$st"); 
    } finally {
      _bloquearListener = false;
    }
  }

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

  void _desfazer() {
    if (_historicoUndo.length > 1) {
      setState(() {
        _bloquearListener = true;
        String atual = _historicoUndo.removeLast();
        _historicoRedo.add(atual);
        _conteudoController.text = _historicoUndo.last;
        _conteudoController.selection = TextSelection.fromPosition(TextPosition(offset: _conteudoController.text.length));
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
        _conteudoController.selection = TextSelection.fromPosition(TextPosition(offset: _conteudoController.text.length));
        _bloquearListener = false;
      });
    }
  }

  Future<void> _fecharComSalvar() async {
    final titulo = _tituloController.text.trim();
    final conteudo = _conteudoController.text.trim();

    if (titulo.isEmpty && conteudo.isEmpty) {
      if (mounted) Navigator.pop(context, false);
      return;
    }

    if (mounted) Navigator.pop(context, true);

    _bloquearListener = true;
    try {
      await _noteRepository.salvarNota(
        notaId: _notaIdAtual,
        idUsuario: widget.idUsuario,
        titulo: titulo.isEmpty ? "Título da nota" : titulo,
        conteudo: conteudo,
        nomeAnexo: _nomeArquivoAnexado,
        caminhoAnexo: _caminhoArquivoAnexado,
      );
    } catch (e, st) {
      debugPrint('[NOTA] erro ao salvar em background: $e\n$st');
    } finally {
      _bloquearListener = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _fecharComSalvar();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    // --- Barra de Topo (Título e Ações Rápidas) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_circle_left_outlined, color: Colors.grey, size: 30),
                                onPressed: _fecharComSalvar,
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
                                icon: const Icon(Icons.attachment, color: Colors.black54),
                                onPressed: _confirmarAnexo,
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
                                    case 'importar':
                                      _confirmarImportacaoConteudo();
                                      break;
                                    case 'copiar':
                                      Clipboard.setData(ClipboardData(text: _conteudoController.text));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Texto copiado!")));
                                      break;
                                    case 'excluir':
                                      _confirmarExclusaoNota();
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
                                    value: 'importar',
                                    child: ListTile(
                                      leading: Icon(Icons.file_download_outlined, size: 20),
                                      title: Text("Importar arquivo (txt/pdf)"),
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

                    // --- Bloco do Arquivo Anexado ---
                    if (_nomeArquivoAnexado != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: InkWell(
                          onTap: _abrirArquivoAnexo,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF31A89C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF31A89C).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file, color: Color(0xFF31A89C), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _nomeArquivoAnexado!, 
                                    style: const TextStyle(
                                      color: Color(0xFF31A89C), 
                                      fontWeight: FontWeight.bold, 
                                      decoration: TextDecoration.underline
                                    ), 
                                    overflow: TextOverflow.ellipsis
                                  )
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                  onPressed: _confirmarExcluirAnexo,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // --- Área de Edição do Conteúdo ---
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

                    // --- Barra Inferior Customizada ---
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
                              child: _buildStatusIcon()
                            ),
                            IconButton(
                              icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white), 
                              onPressed: () => _conteudoController.clear()
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.undo_rounded, color: _historicoUndo.length > 1 ? Colors.white : Colors.white24), 
                              onPressed: _historicoUndo.length > 1 ? _desfazer : null
                            ),
                            IconButton(
                              icon: Icon(Icons.redo_rounded, color: _historicoRedo.isNotEmpty ? Colors.white : Colors.white24), 
                              onPressed: _historicoRedo.isNotEmpty ? _refazer : null
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_estaCarregando)
              Container(
                color: Colors.black26, 
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF31A89C))
                )
              ),
          ],
        ),
      ),
    );
  }
}