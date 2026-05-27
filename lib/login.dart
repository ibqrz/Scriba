import 'package:flutter/material.dart';
import 'package:scriba/home.dart';
import 'package:scriba/helpers/form_validators.dart';
import 'package:scriba/repositories/auth_repository.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _senhaEscondida = true;
  bool _carregando = false;

  final Color corPrincipal = const Color.fromARGB(255, 49, 168, 156);

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    final erroValidacao = FormValidators.validateLogin(
      username: email,
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
      final resultado = await _authRepository.autenticarUsuario(
        username: email,
        senha: senha,
      );

      if (!mounted) return;

      if (resultado == null || resultado['success'] != true) {
        final mensagemErro = resultado?['message']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErro ?? 'Credenciais inválidas.'),
          ),
        );
        return;
      }

      final usuarioFinal = resultado['user'] as Map<String, dynamic>?;

      if (usuarioFinal == null) {
        // API autenticou, mas não há usuário persistido localmente.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login confirmado pela API, porém falha ao salvar usuário localmente. Algumas funcionalidades locais podem estar indisponíveis.'),
            duration: Duration(seconds: 4),
          ),
        );
      }

      final int idParaNavegar = usuarioFinal != null && usuarioFinal['id_usuario'] is int
          ? usuarioFinal['id_usuario'] as int
          : -1;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            idUsuario: idParaNavegar,
            nomeUsuario: usuarioFinal?['nome']?.toString(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao fazer login: ${e.toString()}')),
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
              'Login',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Digite seus dados para acessar suas notas novamente',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 200),
            Center(
              child: TextField(
                controller: _emailController,
                cursorColor: corPrincipal,
                decoration: InputDecoration(
                  labelText: 'Digite seu usuário ou e-mail',
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: corPrincipal), // Cor do label quando sobe
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(width: 2.0, color: Colors.black), // Borda normal
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 2.0, color: corPrincipal), // Borda quando clica
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
                    onPressed: _carregando ? null : _fazerLogin,
                    child: Text(_carregando ? 'ENTRANDO...' : 'FAZER LOGIN'),
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