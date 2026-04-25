import 'package:flutter/material.dart';
import 'home.dart';
import 'database_helper.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
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

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe e-mail e senha.')),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final usuario = await DatabaseHelper.instance.autenticarUsuario(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      if (usuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciais invalidas.')),
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao fazer login.')),
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
                cursorColor: corPrincipal, // muda a cor do cursor (o tracinho que pisca)
                decoration: InputDecoration(
                  labelText: 'Digite seu e-mail',
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
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
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