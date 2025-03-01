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

  // To Json
  Map<String, dynamic> toJson() => {
        'languageId': languageId,
        'nativeText': nativeText,
        'nativeNote': nativeNote,
        'localText': localText,
        'localRomanization': localRomanization
      };

  // From Json
  factory LanguageCard.fromJson(Map<String, dynamic> json) => LanguageCard(
      languageId: json['languageId'],
      nativeText: json['nativeText'],
      nativeNote: json['nativeNote'],
      localText: json['localText'],
      localRomanization: json['localRomanization']);
}
