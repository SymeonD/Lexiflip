class LanguageCard {
  final int? languageCardId;

  final int languageId;
  final String nativeText;
  final String? nativeNote;
  final String localText;
  final String? localRomanization;

  LanguageCard(
      {this.languageCardId,
      required this.languageId,
      required this.nativeText,
      this.nativeNote,
      required this.localText,
      this.localRomanization});
}
