# 📊 Análise Completa do App Scriba

## Documentação Técnica Detalhada

---

## 1. ARQUITETURA GERAL DO APP

```
Scriba (Flutter App)
├── Frontend (Flutter UI)
├── Local Storage (SQLite)
├── Repository Pattern
├── API Service (HTTP)
└── Proxy Server (Dart CLI)
```

O app segue o padrão **Repository Pattern** com separação clara de responsabilidades:
- **Telas** (UI): Widgets Flutter que exibem dados
- **Repositories**: Intermediários entre UI e dados
- **API Service**: Gerencia chamadas HTTP
- **Database Helper**: Gerencia SQLite local
- **Proxy Server**: Roteia requisições web para as APIs reais

---

## 2. FLUXO DE AUTENTICAÇÃO

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUXO DE LOGIN/REGISTRO                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Usuário entra credenciais (LoginTela/CadastroTela)          │
│     ↓                                                           │
│  2. FormValidators.validateLogin() - Valida campos              │
│     ↓                                                           │
│  3. AuthRepository.autenticarUsuario()                          │
│     ├─ Tenta validar localmente no SQLite                       │
│     └─ Se falhar, chama ApiService.login()                      │
│        ↓                                                        │
│  4. ApiService.login() - HTTP POST                              │
│     ├─ Endpoint: https://mobile-ios-login.zani0x03.eti.br/api   │
│     ├─ Body: {username, password, sistemaId}                    │
│     └─ Recebe: access_token, user data                          │
│        ↓                                                        │
│  5. JWT Token é decodificado (extrairDadosDoToken)              │
│     ├─ Extrai nome, sobrenome, email                            │
│     └─ Trata nomes duplicados inteligentemente                  │
│        ↓                                                        │
│  6. Usuário é salvo no SQLite local                             │
│     ├─ Tabela: usuario                                          │
│     └─ Token armazenado com timestamp                           │
│        ↓                                                        │
│  7. Navega para HomePage                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Detalhes importantes:**
- **Token extraído via JWT decoder**: O app decodifica o token JWT para extrair dados do usuário
- **Validação inteligente de nome**: Se `sobrenome` vem vazio, ele separa `nome` em nome+sobrenome
- **Sincronização**: Primeiro tenta BD local, depois API externa
- **Armazenamento**: Token é salvo com `token_criado_em` para rastrear expiração

---

## 3. ESTRUTURA DO BANCO DE DADOS (SQLite)

```sql
┌─────────────────────────────────────┐
│ TABELA: usuario                     │
├─────────────────────────────────────┤
│ id_usuario (PK)                     │
│ nome, sobrenome                     │
│ login, email (UNIQUE)               │
│ senha_hash                          │
│ token (JWT - Bearer Auth)           │
│ sistema_id (UUID do sistema)        │
│ token_criado_em (TIMESTAMP)         │
│ criado_em, atualizado_em            │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ TABELA: nota                        │
├─────────────────────────────────────┤
│ id_nota (PK)                        │
│ id_usuario (FK → usuario)           │
│ titulo, conteudo                    │
│ nome_anexo, caminho_anexo           │
│ criado_em, atualizado_em            │
│ deletado_em (soft delete)           │
└─────────────────────────────────────┘
```

**Versões do banco:**
- **v1**: Schema inicial
- **v2**: Adicionou anexos nas notas, campos extras em usuário
- **v3**: Adicionou `token_criado_em` para rastrear expiração

---

## 4. CAMADA DE TELAS (Frontend)

| Tela | Função | Conexões |
|------|--------|----------|
| **MainApp** | Splash screen inicial | Carrega LoginTela ou CadastroTela |
| **LoginTela** | Autenticação | AuthRepository → ApiService |
| **CadastroTela** | Registro novo usuário | AuthRepository → ApiService |
| **HomePage** | Lista notas do usuário | NoteRepository → DatabaseHelper |
| **NotaTela** | Editor de notas com anexos | NoteRepository, FilePicker, Syncfusion PDF |
| **ChatTela** | Chat com IA | ChatRepository → ApiService (IA) |
| **HistoricoTela** | Histórico de chats | ChatRepository (em memória) |

---

## 5. FLUXO DE NOTAS

```
┌────────────────────────────────────────────────────────┐
│           CICLO DE VIDA DE UMA NOTA                    │
├────────────────────────────────────────────────────────┤
│                                                        │
│  Criar/Editar:                                         │
│  NotaTela (UI) → NoteRepository → DatabaseHelper       │
│  └─ INSERT ou UPDATE em tabela nota                    │
│  └─ Com debounce automático (salva a cada 2s)          │
│                                                        │
│  Anexos (PDF/TXT/MD):                                  │
│  FilePicker → Lê arquivo → Salva path no BD            │
│  └─ Sincfusion PDF para visualizar PDFs                │
│  └─ OpenFileX para abrir documentos                    │
│                                                        │
│  Undo/Redo:                                            │
│  Histórico local de conteúdo                           │
│  └─ _historicoUndo, _historicoRedo arrays              │
│                                                        │
│  Deletar:                                              │
│  Soft delete (marca deletado_em)                       │ 
│  └─ Pode ser restaurado depois                         │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 6. SISTEMA DE CHAT COM IA

```
┌────────────────────────────────────────────────────────┐
│         FLUXO DE CONVERSA COM IA                       │
├────────────────────────────────────────────────────────┤
│                                                        │
│  1. Usuário abre uma nota                              │
│  2. Clica em "Chat IA"                                 │
│     ↓                                                  │
│  3. ChatRepository.criarConversa()                     │
│     └─ ID: timestamp em ms                             │
│     └─ Armazenada em _conversas list (memória)         │
│        ↓                                               │
│  4. Usuário digita mensagem                            │
│     ↓                                                  │
│  5. ChatTela adiciona msg ao histórico local           │
│     ├─ isUser: true                                    │
│     └─ Scroll para bottom                              │ 
│        ↓                                               │
│  6. ChatRepository.responderMensagem()                 │
│     └─ Prepara histórico (últimas 10 msgs)             │
│     └─ Envia para ApiService.enviarPromptIa()          │
│        ↓                                               │
│  7. ApiService faz POST para IA API                    │
│     ├─ Endpoint: /api/chat ou /api/prompt              │
│     ├─ Headers: Authorization: Bearer {token}          │
│     ├─ Body: {prompt, history, titulo}                 │
│     └─ Extrai resposta (tenta múltiplos campos)        │
│        ↓                                               │
│  8. Resposta adicionada ao histórico                   │
│     ├─ isUser: false                                   │
│     └─ Atualiza lastUpdate da conversa                 │
│        ↓                                               │
│  9. Usuário pode ver histórico completo                │
│     └─ HistoricoTela mostra conversas prévias          │
│                                                        │
│  🔐 Autenticação: Token JWT em header Authorization    │
│  💾 Persistência: Em memória (não persiste ao fechar)  │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 7. CAMADA DE API SERVICE (HTTP)

```dart
ApiService (Static)
├─ Endpoints de Autenticação:
│  ├─ /api/auth/login (POST)
│  ├─ /api/register (POST)
│  └─ /api/auth/verify (GET)
│
├─ Endpoints de IA:
│  ├─ /api/chat (POST)
│  ├─ /api/prompt (POST)
│  └─ /api/chat/history (GET)
│
└─ Métodos auxiliares:
   ├─ _extractToken(): Higieniza tokens JWT
   ├─ extrairDadosDoToken(): Decodifica JWT
   ├─ _resolveWebProxyBaseUrl(): Detecta proxy na web
   └─ _authEndpoint()/_iaEndpoint(): Resolve URLs corretas
```

**Fluxo de requisição:**
```
Aplicação → ApiService
           ├─ kIsWeb ? use proxy : use URL direta
           ├─ Adiciona headers (Authorization: Bearer {token})
           ├─ Converte JSON
           ├─ Trata erros
           └─ Retorna Map<String, dynamic>
```

---

## 8. PROXY SERVER (Localhost:8080)

O proxy é um servidor Dart puro que roda localmente quando você executa `dart run tool/dev_runner.dart`.

```dart
╔════════════════════════════════════════════════════════╗
║          PROXY SERVER (api_proxy_server.dart)          ║
╠════════════════════════════════════════════════════════╣
║                                                        ║
║  1. Bind em localhost:8080                            ║
║     └─ anyIPv4 para aceitar rede local também        ║
║                                                        ║
║  2. Intercepta requests:                              ║
║                                                        ║
║     /health → 200 OK (check de saúde)                 ║
║                                                        ║
║     /proxy/auth/* → Roteia para AUTH API              ║
║     /proxy/ia/* → Roteia para IA API                  ║
║                                                        ║
║  3. Adiciona CORS headers:                            ║
║     ├─ Access-Control-Allow-Origin: *                │
║     ├─ Allow Methods: GET, POST, PUT, PATCH, DELETE  │
║     └─ Permite qualquer header (desenvolvimento)      │
║                                                        ║
║  4. Remove headers problemáticos:                     ║
║     ├─ Request: Host, Content-Length, Connection     │
║     └─ Response: Content-Length, Connection, etc     ║
║                                                        ║
║  5. Pipe do corpo na request/response:                ║
║     └─ Encaminha streams de dados transparentemente  ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
```

**Por que precisa de proxy?**
- Web browsers têm restrição CORS
- Não pode fazer requisições cross-origin direto
- Proxy local simula mesma origem

---

## 9. DEV RUNNER (dev_runner.dart)

Script que automatiza o desenvolvimento:

```dart
┌─────────────────────────────────────────────────────────┐
│  FLUXO: dart run tool/dev_runner.dart [alvo]            │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Parse argumentos:                                   │
│     ├─ chrome: Roda em browser                          │
│     ├─ mobile/android: Detecta device USB               │
│     └─ emulator: Roda em emulador                       │
│                                                          │
│  2. Detecta dispositivo mobile (se aplicável):          │
│     ├─ flutter devices                                  │
│     ├─ Procura (mobile) na saída                        │
│     └─ Extrai ID do dispositivo                         │
│                                                          │
│  3. Se mobile, configura port forwarding:               │
│     ├─ adb forward tcp:8080 tcp:8080                    │
│     └─ Permite que device acesse proxy no PC            │
│                                                          │
│  4. Inicia proxy paralelo:                              │
│     ├─ dart run tool/api_proxy_server.dart              │
│     └─ Escuta em :8080                                 │
│                                                          │
│  5. Inicia Flutter paralelo:                            │
│     ├─ flutter run -d {device_id}                      │
│     └─ Com hot reload habilitado                        │
│                                                          │
│  6. Aguarda processo:                                   │
│     └─ SIGINT (Ctrl+C) limpa tudo e exit              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 10. FLUXO COMPLETO: DO FRONTEND ATÉ A API

```
WEB BROWSER / MOBILE APP
       ↓
   ┌───────────────────────────┐
   │  1. User Action (Login)   │
   └─────────────┬─────────────┘
                 ↓
   ┌─────────────────────────────────────┐
   │  2. FormValidators.validateLogin()  │
   │     Valida email/senha              │
   └─────────────┬───────────────────────┘
                 ↓
   ┌─────────────────────────────────────┐
   │  3. AuthRepository.autenticarUsuario│
   │     ├─ Tenta local (SQLite)        │
   │     └─ Se falha, chama ApiService  │
   └─────────────┬───────────────────────┘
                 ↓
   ┌──────────────────────────────────────────┐
   │  4. ApiService.login()                   │
   │     ├─ Resolve endpoint (proxy ou direto)│
   │     └─ HTTP POST com credentials        │
   └─────────────┬────────────────────────────┘
                 ↓
   
   *** SE WEB: Passa pelo proxy ***
   ┌──────────────────────────────────────┐
   │  5. Localhost:8080 (Proxy)           │
   │     ├─ Detecta /proxy/auth/*         │
   │     ├─ Roteia para AUTH API          │
   │     └─ Adiciona CORS headers         │
   └─────────────┬────────────────────────┘
                 ↓
   *** SE MOBILE: Vai direto ***
   
   ┌──────────────────────────────────────────────┐
   │  6. AUTH API (https://...login.../api)       │
   │     ├─ Recebe credentials                    │
   │     ├─ Valida contra backend                 │
   │     └─ Retorna {access_token, user_data}    │
   └─────────────┬────────────────────────────────┘
                 ↓
   ┌──────────────────────────────────────────────┐
   │  7. ApiService processa response             │
   │     ├─ Extrai token                          │
   │     ├─ Decodifica JWT                        │
   │     ├─ Higieniza dados                       │
   │     └─ Retorna Map ao Repository             │
   └─────────────┬────────────────────────────────┘
                 ↓
   ┌──────────────────────────────────────────────┐
   │  8. AuthRepository salva no SQLite           │
   │     ├─ INSERT usuario table                  │
   │     └─ Armazena token com timestamp          │
   └─────────────┬────────────────────────────────┘
                 ↓
   ┌──────────────────────────────────────────────┐
   │  9. HomePage carregada                       │
   │     └─ Usuário logado com sucesso            │
   └──────────────────────────────────────────────┘
```

---

## 11. REPOSITÓRIOS E PADRÃO DE DADOS

```
┌─────────────────────────────────────────────────────────┐
│             REPOSITORY PATTERN                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  AuthRepository                                         │
│  ├─ registrarUsuario()                                 │
│  │  ├─ Chama ApiService.registrar()                    │
│  │  ├─ Se sucesso, faz login automático                │
│  │  ├─ Salva no SQLite                                 │
│  │  └─ Retorna {success, user, token}                 │
│  │                                                      │
│  └─ autenticarUsuario()                                │
│     ├─ Tenta DatabaseHelper local primeiro             │
│     ├─ Se falha, chama ApiService.login()              │
│     └─ Sincroniza token com local                      │
│                                                          │
│  NoteRepository                                         │
│  ├─ listarNotas(idUsuario)                             │
│  │  └─ SELECT * FROM nota WHERE id_usuario = ?         │
│  │                                                      │
│  ├─ salvarNota(titulo, conteudo, idUsuario, ...)       │
│  │  ├─ INSERT se notaId == null                        │
│  │  ├─ UPDATE se notaId != null                        │
│  │  └─ Salva anexos (nome e caminho)                   │
│  │                                                      │
│  └─ excluirNota(idNota, idUsuario)                     │
│     └─ Soft delete (marca deletado_em)                 │
│                                                          │
│  ChatRepository (Singleton)                            │
│  ├─ criarConversa(titulo)                              │
│  │  └─ Salva em memória (_conversas list)              │
│  │                                                      │
│  ├─ responderMensagem(conversa, mensagem, titulo)      │
│  │  ├─ Prepara histórico (últimas 10 msgs)             │
│  │  ├─ Chama ApiService.enviarPromptIa()               │
│  │  └─ Adiciona resposta ao histórico                  │
│  │                                                      │
│  └─ removerConversa(conversa)                          │
│     └─ Remove de memória                               │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 12. SEGURANÇA E AUTENTICAÇÃO

```
┌────────────────────────────────────────────┐
│        FLUXO DE AUTENTICAÇÃO JWT           │
├────────────────────────────────────────────┤
│                                             │
│  1️⃣ Login                                   │
│  POST /api/auth/login                      │
│  Response: {access_token: "eyJhbGc..."}    │
│                                             │
│  2️⃣ Decodificação JWT                      │
│  Token formato: header.payload.signature   │
│  └─ Payload (base64url) contém dados:     │
│     {name, email, preferred_username}     │
│                                             │
│  3️⃣ Higienização de Token                  │
│  Função _extractToken():                   │
│  ├─ Remove aspas extras                    │
│  ├─ Remove espaços/quebras de linha        │
│  └─ Evita erro de formato em Bearer header │
│                                             │
│  4️⃣ Armazenamento Seguro                   │
│  ├─ Salvo em SQLite local (não é cloud)   │
│  ├─ Com timestamp de criação               │
│  └─ Verificação de expiração ao abrir app │
│                                             │
│  5️⃣ Cada Requisição à IA                   │
│  Header: Authorization: Bearer {token}     │
│  └─ Token validado no servidor             │
│                                             │
│  6️⃣ Token Expirado?                        │
│  ├─ _verificarTokenEExpirado()             │
│  ├─ Limpa token expirado                   │
│  └─ Redireciona para login                 │
│                                             │
└────────────────────────────────────────────┘
```

---

## 13. FERRAMENTAS E DEPENDÊNCIAS EXTERNAS

| Dependência | Uso | Plataforma |
|-------------|-----|-----------|
| **http** | Requisições HTTP | Todas |
| **sqflite** | Banco SQLite | Mobile (iOS/Android) |
| **sqflite_common_ffi** | Banco para Desktop | Windows/Linux/macOS |
| **sqflite_common_ffi_web** | Banco para Web | Web |
| **file_picker** | Seleção de arquivos | Todas |
| **open_filex** | Abrir documentos | Todas |
| **syncfusion_flutter_pdf** | Visualizar/editar PDF | Todas |
| **path** | Manipulação de caminhos | Todas |
| **flutter_lints** | Análise de código | Dev |

---

## 14. FLUXO DE INICIALIZAÇÃO DO APP

```
main()
├─ WidgetsFlutterBinding.ensureInitialized()
│  └─ Prepara binding antes de runApp()
│
├─ SystemChrome.setEnabledSystemUIMode()
│  └─ Configura barra de status/navegação visível
│
└─ runApp(MaterialApp)
   ├─ MainApp (Splash)
   │  ├─ Image.asset('assets/inicial.png')
   │  ├─ Botões: Login | Cadastro
   │  └─ SystemUiOverlayStyle (barra transparente)
   │
   ├─ LoginTela (Se usuário clica "Login")
   │  ├─ TextFields: email + senha
   │  ├─ Validação
   │  └─ NavegaPara: HomePage
   │
   └─ CadastroTela (Se usuário clica "Cadastro")
      ├─ TextFields: nome, sobrenome, login, email, senha
      ├─ Validação
      └─ NavegaPara: HomePage
```

---

## 15. RESUMO DA ARQUITETURA

```
┌─────────────────────────────────────────────────────────────┐
│                    DIAGRAMA DE CAMADAS                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─ PRESENTATION LAYER ─────────────────────┐               │
│  │ • MainApp, LoginTela, HomePage           │               │
│  │ • ChatTela, NotaTela, HistoricoTela      │               │
│  │ • FormValidators helpers                 │               │
│  └──────────────────────────────────────────┘               │
│           ↓                                                  │
│  ┌─ APPLICATION LAYER (Repositories) ───────┐               │
│  │ • AuthRepository                         │               │
│  │ • NoteRepository                         │               │
│  │ • ChatRepository                         │               │
│  └──────────────────────────────────────────┘               │
│           ↓                                                  │
│  ┌─ DATA LAYER ──────────────────────────────┐               │
│  │ ┌─ LOCAL ─────────────────┐              │               │
│  │ │ • DatabaseHelper        │              │               │
│  │ │ • ChatHistory (memory)  │              │               │
│  │ └─────────────────────────┘              │               │
│  │ ┌─ REMOTE ────────────────┐              │               │
│  │ │ • ApiService (HTTP)     │              │               │
│  │ │ • JWT handling          │              │               │
│  │ └─────────────────────────┘              │               │
│  └──────────────────────────────────────────┘               │
│           ↓                                                  │
│  ┌─ EXTERNAL SERVICES ───────────────────────┐               │
│  │ • AUTH API (login.zani0x03.eti.br)       │               │
│  │ • IA API (ia.zani0x03.eti.br)            │               │
│  │ • Localhost Proxy (:8080)                │               │
│  └──────────────────────────────────────────┘               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 16. PRINCIPAIS TECNOLOGIAS UTILIZADAS

### Frontend
- **Flutter**: Framework multiplataforma
- **Material Design**: Design system do Google
- **Dart**: Linguagem de programação

### Backend Local
- **SQLite**: Banco de dados relacional leve
- **Dart**: Linguagem para proxy e dev runner

### APIs Externas
- **REST API**: Autenticação e processamento de IA
- **JWT**: Tokens de autenticação segura

### Ferramentas de Desenvolvimento
- **File Picker**: Gerenciamento de arquivos
- **Syncfusion PDF**: Manipulação de PDFs
- **HTTP Client**: Requisições HTTP

---

## 17. FLUXOS PRINCIPAIS

### Autenticação
1. Usuário insere credenciais
2. Validação local ou remota
3. Recebimento de JWT Token
4. Decodificação e armazenamento
5. Acesso ao app

### Criação de Nota
1. Usuário cria nota na HomePage
2. Abre editor (NotaTela)
3. Escreve conteúdo com debounce
4. Pode adicionar anexos (PDF/TXT/MD)
5. Salva no SQLite local

### Chat com IA
1. Usuário seleciona uma nota
2. Clica em "Chat IA"
3. Digite mensagem
4. Envia via ApiService
5. Recebe resposta da IA
6. Histórico armazenado em memória

---

## 18. CONCLUSÃO

Seu app **Scriba** é um gerenciador de notas inteligente com integração de IA, construído com:

✅ **Frontend robusto** em Flutter  
✅ **Backend local** com SQLite  
✅ **Autenticação JWT** segura  
✅ **API externa** para IA e autenticação  
✅ **Proxy local** para desenvolvimento web  
✅ **Padrão Repository** bem estruturado  
✅ **Suporte multiplataforma** (iOS, Android, Web, Desktop)  

A arquitetura permite fácil manutenção, testes e expansão de funcionalidades! 🚀

---

## 19. ESTRUTURA DE ARQUIVOS DO PROJETO

```
lib/
├── main.dart                           # Entry point + MainApp
├── login.dart                          # Tela de login
├── cadastro.dart                       # Tela de cadastro
├── home.dart                           # Página principal
├── nota.dart                           # Editor de notas
├── chat.dart                           # Chat com IA
├── chat_model.dart                     # Modelos de chat
├── historico.dart                      # Histórico de chats
├── api_service.dart                    # Serviço de API
├── database_helper.dart                # Helper do SQLite
├── helpers/
│   └── form_validators.dart            # Validadores de formulário
└── repositories/
    ├── auth_repository.dart            # Repository de autenticação
    ├── chat_repository.dart            # Repository de chat
    └── note_repository.dart            # Repository de notas

tool/
├── api_proxy_server.dart               # Proxy servidor HTTP
└── dev_runner.dart                     # Executor de desenvolvimento

assets/
├── inicial.png                         # Imagem de splash
└── home.png                            # Imagem da home
```

---

**Documento gerado em**: 3 de junho de 2026

**Versão do App**: 0.1.0+1

**SDK Dart**: ^3.11.3
