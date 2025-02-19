import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';

class Language {
  final int? languageId;
  final List<LanguageCard>? languageCards;
  final List<LanguageDeck>? languageDecks;

  final String languageCode;
  final String languageName;

  Language(
      {this.languageId,
      this.languageCards,
      this.languageDecks,
      required this.languageCode,
      required this.languageName});

  Map<String, Object?> toMap() {
    return {
      'languageCode': languageCode,
      'languageName': languageName,
    };
  }
}
