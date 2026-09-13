class CountryCard {
  final int? countryCardId;

  final int countryId;
  final String nativeText;
  final String? nativeNote;
  final String localText;
  final String? localRomanization;

  CountryCard(
      {this.countryCardId,
      required this.countryId,
      required this.nativeText,
      this.nativeNote,
      required this.localText,
      this.localRomanization});
}
