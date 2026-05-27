<p id="desc"></p>

Aplicativo acadêmico de gerenciamento de notas desenvolvido em Flutter, com cadastro e login, persistência local em SQLite e integração com API remota de autenticação e inteligência artificial.

## Visão Geral

O Scriba foi estruturado para permitir:

- criar usuário local e remoto no mesmo fluxo;
- fazer login com validação local e, quando necessário, validação na API;
- reaproveitar o token salvo localmente por até 24 horas sem chamar a API novamente;
- armazenar token com validade de 24 horas;
- criar, editar, listar e excluir notas por usuário;
- acessar chat com IA usando `Bearer token`.

## Tecnologias Utilizadas

- Flutter
- Dart 3.11.x
- HTTP via `http`
- SQLite via `sqflite`
- SQLite desktop via `sqflite_common_ffi`
- SQLite web via `sqflite_common_ffi_web`

## Estrutura Principal

- `lib/main.dart`: tela inicial do app
- `lib/cadastro.dart`: cadastro com API + banco local
- `lib/login.dart`: login com API + banco local
- `lib/home.dart`: home, verificação de token e lista de notas
- `lib/database_helper.dart`: acesso ao SQLite e migrações
- `lib/api_service.dart`: integração HTTP com as APIs remotas
- `lib/repositories/auth_repository.dart`: orquestra cadastro e login juntando API + banco local
- `lib/repositories/note_repository.dart`: orquestra CRUD de notas com o banco local
- `lib/repositories/chat_repository.dart`: orquestra histórico local e respostas do chat
- `lib/helpers/form_validators.dart`: validação compartilhada de formulários
- `lib/nota.dart`: cadastro e edição de notas
- `lib/chat.dart`: chat da aplicação
- `lib/historico.dart`: histórico de conversas
- `lib/chat_model.dart`: modelo de dados do chat

## Árvore final do projeto

```text
scriba/
├─ android/
├─ assets/
├─ ios/
├─ lib/
│  ├─ api_service.dart
│  ├─ cadastro.dart
│  ├─ chat.dart
│  ├─ chat_model.dart
│  ├─ database_helper.dart
│  ├─ helpers/
│  │  └─ form_validators.dart
│  ├─ historico.dart
│  ├─ home.dart
│  ├─ login.dart
│  ├─ main.dart
│  ├─ nota.dart
│  └─ repositories/
│     ├─ auth_repository.dart
│     ├─ chat_repository.dart
│     └─ note_repository.dart
├─ linux/
├─ macos/
├─ pubspec.yaml
├─ pubspec.lock
├─ README.md
├─ test/
├─ tool/
├─ web/
└─ windows/
```

### Legenda da Estrutura

- `lib/`: código-fonte principal do app Flutter.
- `lib/helpers/`: validações reutilizáveis de formulário.
- `lib/repositories/`: camada de orquestração entre UI, API e banco local.
- `tool/`: utilitários do projeto, como o proxy da API para web.
- `test/`: pasta reservada para testes automatizados.
- `web/`: recursos da versão web do aplicativo.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`: plataformas suportadas pelo Flutter.

## Fluxo da Aplicação

1. O usuário abre a tela inicial.
2. Escolhe cadastro ou login.
3. O cadastro faz duas ações:
	 - cria o usuário na API remota;
	 - grava o usuário no SQLite local.
4. O login primeiro tenta validar usuário e senha no banco local.
5. Se existir token local ainda válido dentro de 24 horas, o app entra sem chamar a API.
6. Se o token não existir ou já tiver expirado, o login chama a API remota, recebe um novo token e atualiza o SQLite local.
7. A Home carrega as notas do usuário e verifica expiração do token.
8. Se o token expirar, o app limpa o token e pede login novamente.

## Separação de Responsabilidades

- `ApiService`: apenas requisições HTTP e token em memória.
- `DatabaseHelper`: apenas SQLite, migrações e operações locais.
- `AuthRepository`: coordena o fluxo de cadastro e login entre API e banco local.
- `NoteRepository`: coordena o CRUD de notas usando apenas o banco local.
- `ChatRepository`: coordena histórico de conversas e respostas do chat.
- `FormValidators`: centraliza as mensagens e regras de validação dos formulários.
- Telas (`cadastro.dart` e `login.dart`): apenas coletam dados da UI e chamam o repositório.
- Telas de notas/chat: apenas renderizam a interface e delegam a regra para seus repositórios.

## Integração com a API

### Base URLs

- Auth: `https://mobile-ios-login.zani0x03.eti.br/api`
- IA: `https://mobile-ios-ia.zani0x03.eti.br/api`

### Endpoints usados

- `POST /register`
- `POST /auth/login`
- `POST /ai/chat`

### Campos Enviados no Cadastro

```json
{
	"name": "Teste",
	"surname": "User",
	"login": "testeuser123",
	"email": "teste123@example.com",
	"password": "senha123",
	"sistemaId": "64b511cc-1392-4d37-85af-9c581961de40"
}
```

### Campos Enviados no Login

```json
{
	"username": "testeuser123",
	"password": "senha123",
	"sistemaId": "64b511cc-1392-4d37-85af-9c581961de40"
}
```

### Resposta Esperada do Login

O backend retorna, entre outros campos:

- `access_token`
- `refresh_token`
- `expires_in`
- `token_type`

## Banco de Dados Local

### Tabela `usuario`

- `id_usuario`
- `nome`
- `sobrenome`
- `login`
- `email`
- `senha_hash`
- `token`
- `token_criado_em`
- `sistema_id`
- `criado_em`
- `atualizado_em`

### Tabela `nota`

- `id_nota`
- `id_usuario`
- `titulo`
- `conteudo`
- `criado_em`
- `atualizado_em`
- `deletado_em`

## Persistência dos Dados

- No Web, o SQLite fica salvo no IndexedDB do navegador.
- No Windows/Linux, o banco é salvo localmente pelo SQLite/FFI.
- O token é salvo no banco e também mantido em memória durante a sessão.

## Validação do Token

- O token fica válido por 24 horas.
- O login pode ser concluído sem nova chamada à API se o token salvo localmente ainda estiver dentro desse prazo.
- A Home verifica se o token expirou ao abrir.
- Quando expira, o app:
	- limpa o token do banco;
	- limpa o token em memória;
	- mostra a mensagem "Token expirado. Por favor, faça login novamente.";
	- redireciona para a tela de login.

## Como Executar

### Instalar dependências

```bash
flutter pub get
```

### Rodar no navegador

```bash
flutter run -d chrome --web-port 1623
```

### Rodar no navegador com proxy automático (modo dev)

Agora usamos um runner Dart que inicia automaticamente o proxy e o Flutter Web. Duas formas:

- **VS Code (F5)** — já configurado: pressione `F5` (configuração "Scriba Dev (Proxy + Flutter Web)").
- **Linha de comando** — execute:

```powershell
dart run tool/dev_runner.dart
```

O `dev_runner.dart` faz:
- inicia `tool/api_proxy_server.dart` (proxy em `http://localhost:8080`)
- espera o proxy responder `/health`
- inicia `flutter run -d chrome` passando `--dart-define=SCRIBA_PROXY_BASE_URL=http://localhost:8080`

Se preferir rodar o Flutter manualmente sem o proxy runner, use `flutter run -d chrome` e assegure que o proxy esteja disponível em `http://localhost:8080`.

### Rodar no desktop Windows

```bash
flutter run -d windows
```

### Analisar o código

```bash
flutter analyze
```

## Testes Manuais Realizados

- cadastro via API retornando `201 Created`;
- login via API retornando `200 OK`;
- token retornando `access_token` e `expires_in`;
- gravação local do usuário e do token no banco.

## Melhorias Futuras

- logout com limpeza completa da sessão;
- refresh token automático;
- integração do chat com persistência completa;
- testes de widget e integração mais amplos;
- hash de senha mais seguro no armazenamento local.

## Captura de Tela

![Tela inicial do Scriba](image.png)
