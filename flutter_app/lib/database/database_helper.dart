import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'source_model.dart';
import 'verification_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('truwave.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE verification_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          verification_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          title TEXT NOT NULL,
          url TEXT NOT NULL,
          FOREIGN KEY (verification_id)
            REFERENCES verifications (id)
            ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE verifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim TEXT NOT NULL,
        verdict TEXT NOT NULL,
        confidence REAL NOT NULL,
        summary TEXT NOT NULL,
        findings TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE verification_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verification_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        FOREIGN KEY (verification_id)
          REFERENCES verifications (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertVerification(
    Verification verification,
    List<VerificationSource> sources,
  ) async {
    final db = await database;

    return db.transaction<int>((txn) async {
      final verificationId = await txn.insert('verifications', {
        'claim': verification.claim,
        'verdict': verification.verdict,
        'confidence': verification.confidence,
        'summary': verification.summary,
        'findings': jsonEncode(verification.findings),
        'created_at': verification.createdAt.toIso8601String(),
      });

      for (final source in sources) {
        await txn.insert('verification_sources', {
          'verification_id': verificationId,
          'name': source.name,
          'title': source.title,
          'url': source.url,
        });
      }

      return verificationId;
    });
  }

  Future<List<Verification>> getVerifications() async {
    final db = await database;
    final result = await db.query('verifications', orderBy: 'created_at DESC');

    return result.map(_verificationFromMap).toList();
  }

  Future<Verification?> getVerification(int id) async {
    final db = await database;
    final result = await db.query(
      'verifications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isEmpty ? null : _verificationFromMap(result.first);
  }

  Verification _verificationFromMap(Map<String, Object?> map) {
    return Verification(
      id: map['id'] as int,
      claim: map['claim'] as String,
      verdict: map['verdict'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      summary: map['summary'] as String,
      findings: List<String>.from(jsonDecode(map['findings'] as String)),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Future<List<VerificationSource>> getSources(int verificationId) async {
    final db = await database;
    final result = await db.query(
      'verification_sources',
      where: 'verification_id = ?',
      whereArgs: [verificationId],
    );

    return result.map(VerificationSource.fromMap).toList();
  }

  Future<int> deleteVerification(int id) async {
    final db = await database;
    return db.delete('verifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllVerifications() async {
    final db = await database;
    return db.delete('verifications');
  }
}
