import 'package:cards/models/language_card.dart';

class LanguageDeck {
  final int? languageDeckId;
  final List<LanguageCard>? languageDeckCards;
  final String languageDeckName;
  final int languageId;
  final bool? isDefault;

  LanguageDeck(
      {this.languageDeckId,
      this.languageDeckCards,
      required this.languageId,
      required this.languageDeckName,
      this.isDefault});
}
