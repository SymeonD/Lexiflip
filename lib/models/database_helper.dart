import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database; // Use nullable Database here

  // Private constructor to prevent instantiation
  DatabaseHelper._privateConstructor();

  // Database getter that initializes the database when it's first used
  Future<Database> get database async {
    if (_database != null) return _database!;

    try {
      // Wait for the database to be initialized
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      // Log error and rethrow
      Logger().e("Error initializing the database: $e");
      rethrow;
    }
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'cards_database.db');

    try {
      return await openDatabase(
        path,
        onCreate: (db, version) async {
          await db.execute(
              "CREATE TABLE IF NOT EXISTS languages (id INTEGER PRIMARY KEY AUTOINCREMENT, languageCode TEXT NOT NULL, languageName TEXT NOT NULL);");

          await db.execute(
              "CREATE TABLE IF NOT EXISTS language_cards (id INTEGER PRIMARY KEY AUTOINCREMENT, languageId integer NOT NULL, nativeText TEXT NOT NULL, nativeNote TEXT, localText TEXT NOT NULL, localRomanization TEXT, FOREIGN KEY (languageId) REFERENCES languages(id) ON DELETE CASCADE);");

          await db.execute(
              "CREATE TABLE IF NOT EXISTS language_decks (id INTEGER PRIMARY KEY AUTOINCREMENT, languageId integer NOT NULL, languageDeckName TEXT NOT NULL, isDefault BOOLEAN NOT NULL DEFAULT 0, FOREIGN KEY (languageId) REFERENCES languages(id) ON DELETE CASCADE);");

          await db.execute(
              "CREATE TABLE IF NOT EXISTS deck_cards (deckId INTEGER NOT NULL, cardId INTEGER NOT NULL, PRIMARY KEY (deckId, cardId), FOREIGN KEY (deckId) REFERENCES language_decks(id) ON DELETE CASCADE, FOREIGN KEY (cardId) REFERENCES language_cards(id) ON DELETE CASCADE);");
        },
        version: 3,
      );
    } catch (e) {
      Logger().e("Error opening the database: $e");
      rethrow;
    }
  }

  // Insert Language into the database
  Future<void> insertLanguage(Language language) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.insert(
        'languages',
        language.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger().e("Error inserting language: $e");
    }
  }

  // Get all the languages from the database
  Future<List<Language>> getLanguages() async {
    try {
      final db = await database; // Wait for the database to be initialized
      final List<Map<String, Object?>> maps = await db.query('languages');

      return List.generate(maps.length, (i) {
        return Language(
          languageId: maps[i]['id'] as int,
          languageCode: maps[i]['languageCode'] as String,
          languageName: maps[i]['languageName'] as String,
        );
      });
    } catch (e) {
      Logger().e("Error getting languages: $e");
      return []; // Return an empty list in case of error
    }
  }

  // Delete a language from the database
  Future<void> deleteLanguage(int languageId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.delete(
        'languages',
        where: "id = ?",
        whereArgs: [languageId],
      );
    } catch (e) {
      Logger().e("Error deleting language: $e");
    }
  }

  // Insert a deck into the database
  Future<int> insertDeck(int languageId, String languageDeckName,
      [bool? isDefault = false]) async {
    try {
      final db = await database; // Wait for the database to be initialized
      return await db.insert(
        'language_decks',
        {
          'languageId': languageId,
          'languageDeckName': languageDeckName,
          'isDefault': isDefault.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger().e("Error inserting deck: $e");
    }
    return -1;
  }

  // Get all the decks for a given language code
  Future<List<LanguageDeck>> getDecks(int languageId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      final List<Map<String, Object?>> maps = await db.query(
        'language_decks',
        where: "languageId = ?",
        whereArgs: [languageId],
      );

      return List.generate(maps.length, (i) {
        return LanguageDeck(
          languageDeckId: maps[i]['id'] as int,
          languageId: maps[i]['languageId'] as int,
          languageDeckName: maps[i]['languageDeckName'] as String,
          isDefault: maps[i]['isDefault'] == 1 ? true : false,
        );
      });
    } catch (e) {
      Logger().e("Error getting decks: $e");
      return []; // Return an empty list in case of error
    }
  }

  // Get the number of cards in a deck
  Future<int> getDeckCardCount(
      int deckId, bool isDefault, int languageId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      // If the deck is not 'All cards', search for the corresponding cards, else search for all cards
      if (!isDefault) {
        final List<Map<String, Object?>> maps = await db.rawQuery(
            "SELECT COUNT(*) FROM deck_cards WHERE deckId = ?", [deckId]);
        return maps[0]['COUNT(*)'] as int;
      } else {
        final List<Map<String, Object?>> maps = await db.rawQuery(
            "SELECT COUNT(*) FROM language_cards WHERE languageId = ?",
            [languageId]);
        return maps[0]['COUNT(*)'] as int;
      }
    } catch (e) {
      Logger().e("Error getting deck card count: $e");
      return 0; // Return 0 in case of error
    }
  }

  // Update a deck name in the database
  Future<void> updateDeckName(int languageDeckId, String newDeckName) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.update(
        'language_decks',
        {'languageDeckName': newDeckName},
        where: "id = ?",
        whereArgs: [languageDeckId],
      );
    } catch (e) {
      Logger().e("Error updating deck name: $e");
    }
  }

  // Delete a deck from the database
  Future<void> deleteDeck(int languageDeckId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.delete(
        'language_decks',
        where: "id = ?",
        whereArgs: [languageDeckId],
      );
    } catch (e) {
      Logger().e("Error deleting deck: $e");
    }
  }

  // Get all the cards for a given deck
  Future<List<LanguageCard?>> getCards(int languageDeckId, int languageId,
      [bool isDefault = false]) async {
    try {
      final db = await database; // Wait for the database to be initialized
      late List<Map<String, Object?>> maps;
      // If the deck is not 'All cards', search for the corresponding cards, else search for all cards
      if (!isDefault) {
        maps = await db.rawQuery(
            "SELECT lc.* FROM language_cards lc JOIN deck_cards dc ON lc.id = dc.cardId WHERE dc.deckId = ?;",
            [languageDeckId]);
      } else {
        maps = await db.rawQuery(
            "SELECT * FROM language_cards WHERE languageId = ?", [languageId]);
      }

      return List.generate(maps.length, (i) {
        return LanguageCard(
          languageCardId: maps[i]['id'] as int,
          languageId: maps[i]['languageId'] as int,
          nativeText: maps[i]['nativeText'] as String,
          nativeNote: maps[i]['nativeNote'] as String?,
          localText: maps[i]['localText'] as String,
          localRomanization: maps[i]['localRomanization'] as String?,
        );
      });
    } catch (e) {
      Logger().e("Error getting cards: $e");
      return []; // Return an empty list in case of error
    }
  }

  // Insert a card into the database
  Future<int> insertCard(LanguageCard card) async {
    try {
      final db = await database; // Wait for the database to be initialized
      return await db.insert(
        'language_cards',
        {
          'languageId': card.languageId,
          'nativeText': card.nativeText,
          'nativeNote': card.nativeNote,
          'localText': card.localText,
          'localRomanization': card.localRomanization
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger().e("Error inserting card: $e");
    }
    return -1;
  }

  // Add a card to a deck
  Future<void> addCardToDeck(int deckId, int cardId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.insert(
        'deck_cards',
        {
          'deckId': deckId,
          'cardId': cardId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger().e("Error adding card to deck: $e");
    }
  }

  // Remove a card from a deck
  Future<void> removeCardFromDeck(int deckId, int cardId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.delete(
        'deck_cards',
        where: "deckId = ? AND cardId = ?",
        whereArgs: [deckId, cardId],
      );
    } catch (e) {
      Logger().e("Error removing card from deck: $e");
    }
  }

  // Update a card in the database
  Future<void> updateCard(LanguageCard card) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.update(
        'language_cards',
        {
          'nativeText': card.nativeText,
          'nativeNote': card.nativeNote,
          'localText': card.localText,
          'localRomanization': card.localRomanization
        },
        where: "id = ?",
        whereArgs: [card.languageCardId],
      );
    } catch (e) {
      Logger().e("Error updating card: $e");
    }
  }

  // Delete a card from the database and from all decks
  // Input: languageCode, nativeText, nativeNote, localText, localRomanization
  Future<void> deleteCard(int languageCardId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.delete(
        'language_cards',
        where: "id = ?",
        whereArgs: [languageCardId],
      );
    } catch (e) {
      Logger().e("Error deleting card: $e");
    }
  }
}
