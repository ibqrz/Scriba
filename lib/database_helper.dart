import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'scriba.db';
  static const int _dbVersion = 3;

  Database? _database;
  bool _factoryConfigured = false;

  Future<Database> get database async {
    if (_database != null) return _database!;

    await _configureDatabaseFactory();

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    if (kDebugMode) {
      debugPrint('SQLite DB path: $path');
    }

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuario (
            id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            sobrenome TEXT,
            login TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            senha_hash TEXT NOT NULL,
            token TEXT,
            sistema_id TEXT,
            criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            atualizado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE nota (
            id_nota INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER NOT NULL,
            titulo TEXT NOT NULL,
            conteudo TEXT NOT NULL,
            criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            atualizado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            deletado_em TEXT,
            FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migração de v1 para v2: adicionar novos campos
          try {
            await db.execute('ALTER TABLE usuario ADD COLUMN sobrenome TEXT');
          } catch (_) {}
          
          try {
            await db.execute('ALTER TABLE usuario ADD COLUMN login TEXT NOT NULL UNIQUE DEFAULT ""');
          } catch (_) {}
          
          try {
            await db.execute('ALTER TABLE usuario ADD COLUMN token TEXT');
          } catch (_) {}
          
          try {
            await db.execute('ALTER TABLE usuario ADD COLUMN sistema_id TEXT');
          } catch (_) {}
        }
        
        if (oldVersion < 3) {
          // Migração de v2 para v3: adicionar campo de timestamp do token
          try {
            await db.execute('ALTER TABLE usuario ADD COLUMN token_criado_em TEXT');
          } catch (_) {}
        }
      },
    );

    await _ensureUsuarioColumns(_database!);

    return _database!;
  }

  Future<void> _configureDatabaseFactory() async {
    if (_factoryConfigured) return;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _factoryConfigured = true;
  }

  Future<void> _ensureUsuarioColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(usuario)');
    final existing = columns
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    Future<void> addColumn(String columnSql) async {
      try {
        await db.execute(columnSql);
      } catch (_) {}
    }

    if (!existing.contains('sobrenome')) {
      await addColumn('ALTER TABLE usuario ADD COLUMN sobrenome TEXT');
    }
    if (!existing.contains('login')) {
      await addColumn('ALTER TABLE usuario ADD COLUMN login TEXT NOT NULL UNIQUE DEFAULT ""');
    }
    if (!existing.contains('token')) {
      await addColumn('ALTER TABLE usuario ADD COLUMN token TEXT');
    }
    if (!existing.contains('sistema_id')) {
      await addColumn('ALTER TABLE usuario ADD COLUMN sistema_id TEXT');
    }
    if (!existing.contains('token_criado_em')) {
      await addColumn('ALTER TABLE usuario ADD COLUMN token_criado_em TEXT');
    }
  }

  String _hashSenha(String senha) {
    return senha.trim();
  }

  Future<Map<String, dynamic>?> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    String? sobrenome,
    String? login,
    String? token,
    String? sistemaId,
  }) async {
    final db = await database;

    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();
    final senhaHash = _hashSenha(senha);
    final loginLimpo = (login ?? emailLimpo).trim();
    final tokenCriadoEm = token != null ? DateTime.now().toIso8601String() : null;

    try {
      final id = await db.insert('usuario', {
        'nome': nomeLimpo,
        'sobrenome': sobrenome?.trim(),
        'login': loginLimpo,
        'email': emailLimpo,
        'senha_hash': senhaHash,
        'token': token,
        'token_criado_em': tokenCriadoEm,
        'sistema_id': sistemaId,
      });

      return {
        'id_usuario': id,
        'nome': nomeLimpo,
        'sobrenome': sobrenome?.trim(),
        'login': loginLimpo,
        'email': emailLimpo,
        'token': token,
        'token_criado_em': tokenCriadoEm,
      };
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> autenticarUsuario({
    String? email,
    String? login,
    required String senha,
  }) async {
    final db = await database;
    final senhaHash = _hashSenha(senha);

    late List<Map<String, dynamic>> resultado;

    if (email != null) {
      final emailLimpo = email.trim().toLowerCase();
      resultado = await db.query(
        'usuario',
        columns: ['id_usuario', 'nome', 'email', 'login', 'token'],
        where: 'email = ? AND senha_hash = ?',
        whereArgs: [emailLimpo, senhaHash],
        limit: 1,
      );
    } else if (login != null) {
      final loginLimpo = login.trim();
      resultado = await db.query(
        'usuario',
        columns: ['id_usuario', 'nome', 'email', 'login', 'token'],
        where: 'login = ? AND senha_hash = ?',
        whereArgs: [loginLimpo, senhaHash],
        limit: 1,
      );
    } else {
      return null;
    }

    if (resultado.isEmpty) return null;
    return resultado.first;
  }

  /// Salva ou atualiza o token de um usuário com timestamp
  Future<void> salvarTokenUsuario({
    required int idUsuario,
    required String token,
    String? sistemaId,
  }) async {
    final db = await database;
    final valores = <String, Object?>{
      'token': token,
      'token_criado_em': DateTime.now().toIso8601String(),
      'atualizado_em': DateTime.now().toIso8601String(),
    };

    if (sistemaId != null) {
      valores['sistema_id'] = sistemaId;
    }

    await db.update(
      'usuario',
      valores,
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  /// Verifica se o token de um usuário expirou (60 minutos)
  Future<bool> tokenExpirou({required int idUsuario}) async {
    final db = await database;
    final resultado = await db.query(
      'usuario',
      columns: ['token', 'token_criado_em', 'atualizado_em'],
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      limit: 1,
    );

    if (resultado.isEmpty) return true;

    final row = resultado.first;
    final token = row['token']?.toString();
    if (token == null || token.isEmpty) return true;

    final tokenCriadoEm = row['token_criado_em']?.toString() ?? row['atualizado_em']?.toString();
    if (tokenCriadoEm == null || tokenCriadoEm.isEmpty) return false;

    try {
      final dataToken = DateTime.parse(tokenCriadoEm.toString());
      final agora = DateTime.now();
      final diferenca = agora.difference(dataToken);

      // 60 minutos = 3600 segundos
      return diferenca.inSeconds > 3600;
    } catch (_) {
      return true;
    }
  }

  /// Limpa o token de um usuário
  Future<void> limparToken({required int idUsuario}) async {
    final db = await database;
    await db.update(
      'usuario',
      {
        'token': null,
        'token_criado_em': null,
        'atualizado_em': DateTime.now().toIso8601String()
      },
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  /// Obtém o usuário pelo email
  Future<Map<String, dynamic>?> obterUsuarioPorEmail(String email) async {
    final db = await database;
    final emailLimpo = email.trim().toLowerCase();
    final resultado = await db.query(
      'usuario',
      where: 'email = ?',
      whereArgs: [emailLimpo],
      limit: 1,
    );

    if (resultado.isEmpty) return null;
    return resultado.first;
  }

  /// Obtém o usuário pelo login
  Future<Map<String, dynamic>?> obterUsuarioPorLogin(String login) async {
    final db = await database;
    final loginLimpo = login.trim();
    final resultado = await db.query(
      'usuario',
      where: 'login = ?',
      whereArgs: [loginLimpo],
      limit: 1,
    );

    if (resultado.isEmpty) return null;
    return resultado.first;
  }

  /// Obtém o usuário pelo id
  Future<Map<String, dynamic>?> obterUsuarioPorId(int idUsuario) async {
    final db = await database;
    final resultado = await db.query(
      'usuario',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      limit: 1,
    );

    if (resultado.isEmpty) return null;
    return resultado.first;
  }

  Future<List<Map<String, dynamic>>> getNotas(int idUsuario) async {
    final db = await database;
    return db.query(
      'nota',
      where: 'id_usuario = ? AND deletado_em IS NULL',
      whereArgs: [idUsuario],
      orderBy: 'atualizado_em DESC',
    );
  }

  Future<void> atualizarTimestamp(int idNota, int idUsuario) async {
    final db = await database;
    await db.update(
      'nota',
      {'atualizado_em': DateTime.now().toIso8601String()},
      where: 'id_nota = ? AND id_usuario = ?',
      whereArgs: [idNota, idUsuario],
    );
  }

  Future<int> inserirNota({
    required String titulo,
    required String conteudo,
    required int idUsuario,
  }) async {
    final db = await database;
    return db.insert('nota', {
      'id_usuario': idUsuario,
      'titulo': titulo,
      'conteudo': conteudo,
      'atualizado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<int> atualizarNota({
    required int idNota,
    required int idUsuario,
    required String titulo,
    required String conteudo,
  }) async {
    final db = await database;
    return db.update(
      'nota',
      {
        'titulo': titulo,
        'conteudo': conteudo,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id_nota = ? AND id_usuario = ? AND deletado_em IS NULL',
      whereArgs: [idNota, idUsuario],
    );
  }

  Future<int> excluirNota({
    required int idNota,
    required int idUsuario,
  }) async {
    final db = await database;
    return db.update(
      'nota',
      {'deletado_em': DateTime.now().toIso8601String()},
      where: 'id_nota = ? AND id_usuario = ? AND deletado_em IS NULL',
      whereArgs: [idNota, idUsuario],
    );
  }
}