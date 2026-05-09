class FormValidators {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  static String? validateCadastro({
    required String nome,
    required String login,
    required String email,
    required String senha,
  }) {
    if (nome.trim().isEmpty || login.trim().isEmpty || email.trim().isEmpty || senha.trim().isEmpty) {
      return 'Preencha todos os campos obrigatórios.';
    }

    if (!isValidEmail(email)) {
      return 'Informe um e-mail valido. Ex.: nome@dominio.com';
    }

    return null;
  }

  static String? validateLogin({
    required String username,
    required String senha,
  }) {
    if (username.trim().isEmpty || senha.trim().isEmpty) {
      return 'Informe e-mail/usuário e senha.';
    }

    return null;
  }
}