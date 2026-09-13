import 'package:cards/models/country_card.dart';
import 'package:cards/models/country_deck.dart';

class Country {
  final int? countryId;
  final List<CountryCard>? countryCards;
  final List<CountryDeck>? countryDecks;

  final String countryCode;
  final String countryName;
  final String countryLanguageCode;

  Country(
      {this.countryId,
      this.countryCards,
      this.countryDecks,
      required this.countryCode,
      required this.countryName,
      required this.countryLanguageCode});

  Map<String, Object?> toMap() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'countryLanguageCode': countryLanguageCode,
    };
  }
}
