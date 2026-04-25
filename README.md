# Scriba

Projeto acadêmico de aplicativo de notas com Flutter, autenticação local e persistência em SQLite.

## Visão geral

O repositório contém um app chamado Scriba, desenvolvido para gerenciamento de notas com fluxo de cadastro, login e CRUD de notas por usuário.

Principais funcionalidades:

- Cadastro de usuário local.
- Login com validação no banco local.
- Criação, edição, listagem e exclusão lógica de notas.
- Isolamento de dados por usuário.
- Chat local e histórico de conversas.

## Estrutura do repositório

- `./`: app Flutter principal.
- `lib/`: código de telas e camada de dados.
- `web/`: arquivos da versão web, incluindo assets do SQLite web.

## Stack técnica

- Flutter 3.41.x
- Dart 3.11.x
- SQLite via `sqflite`
- Suporte SQLite em desktop/web via `sqflite_common_ffi` e `sqflite_common_ffi_web`

## Modelo de dados (resumo)

Entidades:

- `usuario`
	- `id_usuario` (PK)
	- `nome`
	- `email` (UNIQUE)
	- `senha_hash`
	- `criado_em`
	- `atualizado_em`

- `nota`
	- `id_nota` (PK)
	- `id_usuario` (FK -> usuario.id_usuario)
	- `titulo`
	- `conteudo`
	- `criado_em`
	- `atualizado_em`
	- `deletado_em` (soft delete)

Relacionamento:

- Um usuário possui várias notas (1:N).

![alt text](image.png)

## Como usar o repositório

### 1) Clonar e entrar no projeto

```bash
git clone <url-do-repositorio>
cd scriba
```

### 2) Instalar dependências

```bash
flutter pub get
```

### 3) Executar no Chrome

```bash
flutter run -d chrome --web-port 8080
```

### 4) Executar análise estática

```bash
flutter analyze
```

## Persistência e ambiente

- Em Web: os dados são salvos no IndexedDB do navegador.
- Em Android/Desktop: os dados ficam em armazenamento local do app.
- Os dados locais não são enviados no `git push`; somente código vai para o repositório.

## Fluxo funcional

1. Usuário se cadastra.
2. Usuário faz login.
3. App carrega notas vinculadas ao usuário logado.
4. Usuário cria, edita e exclui notas.
5. Exclusão de nota é lógica (`deletado_em`).

## Orientação técnica para evolução

- Substituir hash simples de senha por hash seguro com salt.
- Criar suíte de testes automatizados (unit e widget).
- Extrair camada de repositórios para separar melhor UI e dados.
- Adicionar persistência de sessão de login.
- Evoluir para backend remoto caso seja necessário sincronizar dados entre dispositivos.
