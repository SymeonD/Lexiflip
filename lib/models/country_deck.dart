import 'package:cards/models/country_card.dart';

class CountryDeck {
  final int? countryDeckId;
  final List<CountryCard>? countryDeckCards;
  final String countryDeckName;
  final int countryId;
  final bool? isDefault;

  CountryDeck(
      {this.countryDeckId,
      this.countryDeckCards,
      required this.countryId,
      required this.countryDeckName,
      this.isDefault});
}
