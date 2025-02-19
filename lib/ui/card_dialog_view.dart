import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardDialogView extends StatefulWidget {
  final Language language;
  final LanguageDeck languageDeck;
  final VoidCallback onCardAdded;

  // Edit parameters
  final LanguageCard? languageCard;

  // Test hero
  final String cardTag;

  const CardDialogView(
      {super.key,
      required this.language,
      required this.languageDeck,
      required this.onCardAdded,
      this.languageCard,
      required this.cardTag});

  @override
  State<CardDialogView> createState() => _CardDialogViewState();
}

class _CardDialogViewState extends State<CardDialogView> {
  // Text field controllers to get the text entered by the user
  final TextEditingController nativeTextController = TextEditingController();
  final TextEditingController nativeNoteController = TextEditingController();
  final TextEditingController localTextController = TextEditingController();
  final TextEditingController localRomanizationController =
      TextEditingController();

  String nativeLanguage = "fr";
  String localLanguage = "en";
  final languageModel = OnDeviceTranslatorModelManager();

  Future<String> translateText(String text, String from, String to) async {
    final translator = OnDeviceTranslator(
      sourceLanguage: BCP47Code.fromRawValue(from)!,
      targetLanguage: BCP47Code.fromRawValue(to)!,
    );

    final translatedText = await translator.translateText(text);
    translator.close(); // Free up resources
    return translatedText;
  }

  @override
  void initState() {
    // Initiate the controllers with the text entered by the user
    if (widget.languageCard != null) {
      nativeTextController.text = widget.languageCard!.nativeText;
      nativeNoteController.text = widget.languageCard!.nativeNote ?? "";
      localTextController.text = widget.languageCard!.localText;
      localRomanizationController.text =
          widget.languageCard!.localRomanization ?? "";
    }
    SharedPreferences.getInstance().then((prefs) {
      nativeLanguage = prefs.getString('lantiveLanguageCode') ?? "fr";
    });
    localLanguage = getLanguageCode(widget.language.languageCode)!;

    // Check if language model is downloaded
    languageModel
        .isModelDownloaded(getLanguageCode(widget.language.languageCode)!)
        .then((value) => {
              Logger()
                  .d("Model ${widget.language.languageCode} downloaded: $value")
            });

    SharedPreferences.getInstance().then((prefs) {
      nativeLanguage = prefs.getString('nativeLanguageCode')!;
      languageModel.isModelDownloaded(nativeLanguage).then(
          (value) => {Logger().d("Model $nativeLanguage downloaded: $value")});
    });

    super.initState();
  }

  @override
  void dispose() {
    nativeTextController.dispose();
    nativeNoteController.dispose();
    localTextController.dispose();
    localRomanizationController.dispose();
    widget.onCardAdded();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            shape: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            // Get the language name from the language code
            title: Padding(
              padding: const EdgeInsets.only(bottom: 5, left: 8),
              child: Row(
                children: [
                  CountryFlag.fromCountryCode(
                    widget.language.languageCode,
                    width: 60,
                    height: 40,
                    shape: const RoundedRectangle(7),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width -
                          150, // Adjust this based on layout
                    ),
                    child: Text(
                      widget.languageDeck.languageDeckName,
                      overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                      maxLines: 1, // Limit to one line
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 16),
                Hero(
                  tag: widget.cardTag,
                  child: SizedBox(
                    height: 250,
                    child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        color: Colors.white,
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          120,
                                      child: TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        controller: nativeTextController,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        decoration: const InputDecoration(
                                            hintText: 'This card\'s word',
                                            hintStyle: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12)),
                                            )),
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.translate_outlined),
                                      color: Colors.black54,
                                      iconSize: 30,
                                      onPressed: () {
                                        Logger().i(
                                            "Translate from $nativeLanguage to $localLanguage : ${widget.language.languageName}");
                                        //TODO: Translate the text
                                        translateText(nativeTextController.text,
                                                nativeLanguage, localLanguage)
                                            .then((value) => {
                                                  localTextController.text =
                                                      value
                                                });
                                      },
                                    )
                                  ],
                                ),
                                TextField(
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: nativeNoteController,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                  decoration: const InputDecoration(
                                      hintText: 'More details or a hint',
                                      hintStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      )),
                                )
                              ],
                            ))),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                SizedBox(
                  height: 250,
                  child: Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      color: Theme.of(context).colorScheme.secondary,
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                cursorColor: Colors.white, // White cursor
                                selectionColor: Colors
                                    .white24, // Light white selection background
                                selectionHandleColor:
                                    Colors.white, // White selection handle
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: localTextController,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  cursorColor: Colors.white,
                                  decoration: const InputDecoration(
                                      hintText: 'This card\'s translation',
                                      hintStyle: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      )),
                                ),
                                TextField(
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: localRomanizationController,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                  cursorColor: Colors.white,
                                  decoration: const InputDecoration(
                                      hintText: 'Romanization',
                                      hintStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      )),
                                ),
                              ],
                            ),
                          ))),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                          onPressed: () {
                            if (widget.languageCard == null) {
                              // Add the card into the database
                              DatabaseHelper.instance
                                  .insertCard(
                                    LanguageCard(
                                      languageId: widget.language.languageId!,
                                      nativeText: nativeTextController.text,
                                      nativeNote: nativeNoteController.text,
                                      localText: localTextController.text,
                                      localRomanization:
                                          localRomanizationController.text,
                                    ),
                                  )
                                  .then((newCardId) => {
                                        if (!widget.languageDeck.isDefault! &&
                                            newCardId != -1)
                                          {
                                            DatabaseHelper.instance
                                                .addCardToDeck(
                                                    widget.languageDeck
                                                        .languageDeckId!,
                                                    newCardId)
                                                .then((value) => {}),
                                          }
                                      });
                              // If the deck is not 'all cards', add the card to the deck
                            } else {
                              // Edit the card
                              DatabaseHelper.instance.updateCard(
                                LanguageCard(
                                  languageId: widget.languageCard!.languageId,
                                  languageCardId:
                                      widget.languageCard!.languageCardId,
                                  nativeText: nativeTextController.text,
                                  nativeNote: nativeNoteController.text,
                                  localText: localTextController.text,
                                  localRomanization:
                                      localRomanizationController.text,
                                ),
                              );
                            }
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            widget.languageCard != null ? 'Edit' : 'Add',
                          )),
                    )
                  ],
                )
              ],
            ),
          )),
    );
  }
}
