import 'package:flutter/material.dart';
import 'home.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {

  bool _senhaEscondida = true;

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
                decoration: InputDecoration(
                  labelText: 'Digite seu e-mail',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Center(
              child: TextField(
                obscureText: _senhaEscondida, 
                decoration: InputDecoration(
                  labelText: 'Digite sua senha',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(width: 2.0),
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaEscondida ? Icons.visibility : Icons.visibility_off,
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
                      backgroundColor: const Color.fromARGB(255, 49, 168, 156),
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                          color: Color.fromARGB(255, 28, 125, 115), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    },
                    child: const Text('FAZER LOGIN'),
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