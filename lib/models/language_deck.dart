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

      // To Json
  Map<String, dynamic> toJson() => {
        'languageDeckId': languageDeckId,
        'languageDeckCards': languageDeckCards,
        'languageId': languageId,
        'languageDeckName': languageDeckName,
        'isDefault': isDefault,
      };

      // From Json
  factory LanguageDeck.fromJson(Map<String, dynamic> json) => LanguageDeck(
        languageDeckId: json['languageDeckId'],
        languageDeckCards: json['languageDeckCards'],
        languageId: json['languageId'],
        languageDeckName: json['languageDeckName'],
        isDefault: json['isDefault'],
      );
}
