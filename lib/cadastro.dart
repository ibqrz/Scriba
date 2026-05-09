import 'package:flutter/material.dart';
import 'package:scriba/home.dart';
import 'package:scriba/helpers/form_validators.dart';
import 'package:scriba/repositories/auth_repository.dart';

class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _sobrenomeController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _senhaEscondida = true;
  bool _carregando = false;

  final Color corPrincipal = const Color.fromARGB(255, 49, 168, 156);

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerCadastro() async {
    final nome = _nomeController.text.trim();
    final sobrenome = _sobrenomeController.text.trim();
    final login = _loginController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    final erroValidacao = FormValidators.validateCadastro(
      nome: nome,
      login: login,
      email: email,
      senha: senha,
    );

    if (erroValidacao != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erroValidacao)),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final resultado = await _authRepository.registrarUsuario(
        nome: nome,
        sobrenome: sobrenome,
        login: login,
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      if (resultado == null || resultado['success'] != true) {
        final mensagemErro = resultado?['message']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErro ?? 'Erro ao registrar usuário.')),
        );
        return;
      }

      final usuario = resultado['user'] as Map<String, dynamic>?;
      if (usuario == null || usuario['id_usuario'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário criado, mas não foi possível carregar os dados locais.'),
          ),
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            idUsuario: usuario['id_usuario'] as int,
            nomeUsuario: usuario['nome']?.toString(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao cadastrar: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

// ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_circle_left_outlined,
                    color: Colors.grey, size: 40),
                onPressed: () => Navigator.pop(context),
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
                controller: _nomeController,
                cursorColor: corPrincipal,
                decoration: InputDecoration(
                  labelText: 'Digite seu nome',
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: corPrincipal),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(width: 2.0, color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 2.0, color: corPrincipal),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextField(
                controller: _sobrenomeController,
                decoration: InputDecoration(
                  labelText: 'Digite seu sobrenome',
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
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: 'Digite seu login (usuário)',
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
                controller: _emailController,
                cursorColor: corPrincipal,
                decoration: InputDecoration(
                  labelText: 'Digite seu e-mail',
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: corPrincipal),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(width: 2.0, color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 2.0, color: corPrincipal),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextField(
                controller: _senhaController,
                obscureText: _senhaEscondida,
                cursorColor: corPrincipal,
                decoration: InputDecoration(
                  labelText: 'Digite sua senha',
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: corPrincipal),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(width: 2.0, color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 2.0, color: corPrincipal),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaEscondida
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaEscondida = !_senhaEscondida;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 60),
                      backgroundColor: corPrincipal,
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                          color: Color.fromARGB(255, 28, 125, 115), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _carregando ? null : _fazerCadastro,
                    child: Text(_carregando ? 'CADASTRANDO...' : 'FAZER CADASTRO'),
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