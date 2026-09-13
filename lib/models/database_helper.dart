import 'package:cards/models/country.dart';
import 'package:cards/models/country_card.dart';
import 'package:cards/models/country_deck.dart';
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
              "CREATE TABLE IF NOT EXISTS countries (id INTEGER PRIMARY KEY AUTOINCREMENT, countryCode TEXT NOT NULL, countryName TEXT NOT NULL, countryLanguageCode TEXT);");

          await db.execute(
              "CREATE TABLE IF NOT EXISTS country_cards (id INTEGER PRIMARY KEY AUTOINCREMENT, countryId integer NOT NULL, nativeText TEXT NOT NULL, nativeNote TEXT, localText TEXT NOT NULL, localRomanization TEXT, FOREIGN KEY (countryId) REFERENCES countries(id) ON DELETE CASCADE);");

          await db.execute(
              "CREATE TABLE IF NOT EXISTS country_decks (id INTEGER PRIMARY KEY AUTOINCREMENT, countryId integer NOT NULL, countryDeckName TEXT NOT NULL, isDefault BOOLEAN NOT NULL DEFAULT 0, FOREIGN KEY (countryId) REFERENCES countries(id) ON DELETE CASCADE);");

          await db.execute(
              "CREATE TABLE IF NOT EXISTS deck_cards (deckId INTEGER NOT NULL, cardId INTEGER NOT NULL, PRIMARY KEY (deckId, cardId), FOREIGN KEY (deckId) REFERENCES country_decks(id) ON DELETE CASCADE, FOREIGN KEY (cardId) REFERENCES country_cards(id) ON DELETE CASCADE);");
        },
        version: 3,
      );
    } catch (e) {
      Logger().e("Error opening the database: $e");
      rethrow;
    }
  }

  // Insert Country into the database
  Future<void> insertCountry(Country country) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.insert(
        'countries',
        country.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger().e("Error inserting country: $e");
    }
  }

  // Get all the countries from the database
  Future<List<Country>> getCountries() async {
    try {
      final db = await database; // Wait for the database to be initialized
      final List<Map<String, Object?>> maps = await db.query('countries');

      return List.generate(maps.length, (i) {
        return Country(
          countryId: maps[i]['id'] as int,
          countryCode: maps[i]['countryCode'] as String,
          countryName: maps[i]['countryName'] as String,
          countryLanguageCode: maps[i]['countryLanguageCode'] as String,
        );
      });
    } catch (e) {
      Logger().e("Error getting countries: $e");
      return []; // Return an empty list in case of error
    }
  }

  // Delete a country from the database
  Future<void> deleteCountry(int countryId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.delete(
        'countries',
        where: "id = ?",
        whereArgs: [countryId],
      );
    } catch (e) {
      Logger().e("Error deleting country: $e");
    }
  }

  // Insert a deck into the database
  Future<int> insertDeck(int countryId, String countryDeckName,
      [bool? isDefault = false]) async {
    try {
      final db = await database; // Wait for the database to be initialized
      return await db.insert(
        'country_decks',
        {
          'countryId': countryId,
          'countryDeckName': countryDeckName,
          'isDefault': isDefault.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger().e("Error inserting deck: $e");
    }
    return -1;
  }

  // Get all the decks for a given country code
  Future<List<CountryDeck>> getDecks(int countryId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      final List<Map<String, Object?>> maps = await db.query(
        'country_decks',
        where: "countryId = ?",
        whereArgs: [countryId],
      );

      return List.generate(maps.length, (i) {
        return CountryDeck(
          countryDeckId: maps[i]['id'] as int,
          countryId: maps[i]['countryId'] as int,
          countryDeckName: maps[i]['countryDeckName'] as String,
          isDefault: maps[i]['isDefault'] == 'true' ? true : false,
        );
      });
    } catch (e) {
      Logger().e("Error getting decks: $e");
      return []; // Return an empty list in case of error
    }
  }

  // Get the number of cards in a deck
  Future<int> getDeckCardCount(
      int deckId, bool isDefault, int countryId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      // If the deck is not 'All cards', search for the corresponding cards, else search for all cards
      if (!isDefault) {
        final List<Map<String, Object?>> maps = await db.rawQuery(
            "SELECT COUNT(*) FROM deck_cards WHERE deckId = ?", [deckId]);
        return maps[0]['COUNT(*)'] as int;
      } else {
        final List<Map<String, Object?>> maps = await db.rawQuery(
            "SELECT COUNT(*) FROM country_cards WHERE countryId = ?",
            [countryId]);
        return maps[0]['COUNT(*)'] as int;
      }
    } catch (e) {
      Logger().e("Error getting deck card count: $e");
      return 0; // Return 0 in case of error
    }
  }

  // Update a deck name in the database
  Future<void> updateDeckName(int countryDeckId, String newDeckName) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.update(
        'country_decks',
        {'countryDeckName': newDeckName},
        where: "id = ?",
        whereArgs: [countryDeckId],
      );
    } catch (e) {
      Logger().e("Error updating deck name: $e");
    }
  }

  // Delete a deck from the database
  Future<void> deleteDeck(int countryDeckId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.delete(
        'country_decks',
        where: "id = ?",
        whereArgs: [countryDeckId],
      );
    } catch (e) {
      Logger().e("Error deleting deck: $e");
    }
  }

  // Get all the cards for a given deck
  Future<List<CountryCard?>> getCards(int countryDeckId, int countryId,
      [bool isDefault = false]) async {
    try {
      final db = await database; // Wait for the database to be initialized
      late List<Map<String, Object?>> maps;
      // If the deck is not 'All cards', search for the corresponding cards, else search for all cards
      if (!isDefault) {
        maps = await db.rawQuery(
            "SELECT lc.* FROM country_cards lc JOIN deck_cards dc ON lc.id = dc.cardId WHERE dc.deckId = ?;",
            [countryDeckId]);
      } else {
        maps = await db.rawQuery(
            "SELECT * FROM country_cards WHERE countryId = ?", [countryId]);
      }

      return List.generate(maps.length, (i) {
        return CountryCard(
          countryCardId: maps[i]['id'] as int,
          countryId: maps[i]['countryId'] as int,
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
  Future<int> insertCard(CountryCard card) async {
    try {
      final db = await database; // Wait for the database to be initialized
      return await db.insert(
        'country_cards',
        {
          'countryId': card.countryId,
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
  Future<void> updateCard(CountryCard card) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.update(
        'country_cards',
        {
          'nativeText': card.nativeText,
          'nativeNote': card.nativeNote,
          'localText': card.localText,
          'localRomanization': card.localRomanization
        },
        where: "id = ?",
        whereArgs: [card.countryCardId],
      );
    } catch (e) {
      Logger().e("Error updating card: $e");
    }
  }

  // Delete a card from the database and from all decks
  // Input: countryCode, nativeText, nativeNote, localText, localRomanization
  Future<void> deleteCard(int countryCardId) async {
    try {
      final db = await database; // Wait for the database to be initialized
      await db.delete(
        'country_cards',
        where: "id = ?",
        whereArgs: [countryCardId],
      );
    } catch (e) {
      Logger().e("Error deleting card: $e");
    }
  }

  Future<void> insertDeckAndCards(int i, deckName, List<CountryCard> cards) async {}
}
