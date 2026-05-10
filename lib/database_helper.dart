import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'scriba.db';
  static const int _dbVersion = 2; 

  Database? _database;
  bool _factoryConfigured = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _configureDatabaseFactory();
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

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
            email TEXT NOT NULL UNIQUE,
            senha_hash TEXT NOT NULL,
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
            nome_anexo TEXT,
            caminho_anexo TEXT,
            criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            atualizado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            deletado_em TEXT,
            FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE nota ADD COLUMN nome_anexo TEXT');
          await db.execute('ALTER TABLE nota ADD COLUMN caminho_anexo TEXT');
        }
      },
    );
    return _database!;
  }

  Future<void> _configureDatabaseFactory() async {
    if (_factoryConfigured) return;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryConfigured = true;
  }

  // --- MÉTODO RESTAURADO PARA CORRIGIR O ERRO NA HOME ---
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
    String? nomeAnexo,
    String? caminhoAnexo,
  }) async {
    final db = await database;
    return db.insert('nota', {
      'id_usuario': idUsuario,
      'titulo': titulo,
      'conteudo': conteudo,
      'nome_anexo': nomeAnexo,
      'caminho_anexo': caminhoAnexo,
      'atualizado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<int> atualizarNota({
    required int idNota,
    required int idUsuario,
    required String titulo,
    required String conteudo,
    String? nomeAnexo,
    String? caminhoAnexo,
  }) async {
    final db = await database;
    return db.update(
      'nota',
      {
        'titulo': titulo,
        'conteudo': conteudo,
        'nome_anexo': nomeAnexo,
        'caminho_anexo': caminhoAnexo,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id_nota = ? AND id_usuario = ?',
      whereArgs: [idNota, idUsuario],
    );
  }

  Future<int> excluirNota({required int idNota, required int idUsuario}) async {
    final db = await database;
    return db.update(
      'nota',
      {'deletado_em': DateTime.now().toIso8601String()},
      where: 'id_nota = ? AND id_usuario = ?',
      whereArgs: [idNota, idUsuario],
    );
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

  Future<Map<String, dynamic>?> cadastrarUsuario({required String nome, required String email, required String senha}) async {
    final db = await database;
    try {
      final id = await db.insert('usuario', {
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'senha_hash': senha.trim(),
      });
      return {'id_usuario': id, 'nome': nome, 'email': email};
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> autenticarUsuario({required String email, required String senha}) async {
    final db = await database;
    final res = await db.query('usuario', where: 'email = ? AND senha_hash = ?', whereArgs: [email.trim().toLowerCase(), senha.trim()], limit: 1);
    return res.isEmpty ? null : res.first;
  }
}