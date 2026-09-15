import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/country.dart';
import 'package:cards/models/country_card.dart';
import 'package:cards/models/country_deck.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardDialogView extends StatefulWidget {
  final Country country;
  final CountryDeck countryDeck;
  final VoidCallback onCardAdded;

  // Edit parameters
  final CountryCard? countryCard;

  // Test hero
  final String cardTag;

  const CardDialogView(
      {super.key,
      required this.country,
      required this.countryDeck,
      required this.onCardAdded,
      this.countryCard,
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
  final countryModel = OnDeviceTranslatorModelManager();
  bool isModelDownloaded = false;

  bool isButtonEnabled = false;

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
    if (widget.countryCard != null) {
      nativeTextController.text = widget.countryCard!.nativeText;
      nativeNoteController.text = widget.countryCard!.nativeNote ?? "";
      localTextController.text = widget.countryCard!.localText;
      localRomanizationController.text =
          widget.countryCard!.localRomanization ?? "";
    }
    SharedPreferences.getInstance().then((prefs) {
      nativeLanguage = prefs.getString('nativeLanguageCode') ?? "fr";
    });
    localLanguage = widget.country.countryLanguageCode;

    countryModel.isModelDownloaded(localLanguage).then((value) => {
          setState(() {
            isModelDownloaded = value;
          })
        });

    countryModel.isModelDownloaded(localLanguage).then(
        (value) => {Logger().d("Model $localLanguage downloaded: $value")});

    countryModel.isModelDownloaded(nativeLanguage).then(
        (value) => {Logger().d("Model $nativeLanguage downloaded: $value")});

    nativeTextController.addListener(() {
      setState(() {
        isButtonEnabled = nativeTextController.text.isNotEmpty &&
            localTextController.text.isNotEmpty;
      });
    });

    localTextController.addListener(() {
      setState(() {
        isButtonEnabled = nativeTextController.text.isNotEmpty &&
            localTextController.text.isNotEmpty;
      });
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
            backgroundColor: ThemeColors.backgroundColor,
            elevation: 0,
            centerTitle: true,
            shape: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            title: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width -
                          150, // Adjust this based on layout
                    ),
                    child: Text(
                      widget.countryDeck.countryDeckName,
                      overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                      maxLines: 1, // Limit to one line
                      style: const TextStyle(
                        color: ThemeColors.primaryFontColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CountryFlag.fromCountryCode(
                  widget.country.countryCode,
                  width: 45,
                  height: 30,
                  shape: const RoundedRectangle(7),
                ),
              ),
            ],
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
                        color: ThemeColors.backgroundColor,
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          120,
                                      // Native text
                                      child: AutoSizeTextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        controller: nativeTextController,
                                        minFontSize: 20,
                                        minLines: 1,
                                        maxLines: 2,
                                        maxLength: 50,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(
                                              RegExp(r"\n"))
                                        ],
                                        textInputAction: TextInputAction.done,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeColors.primaryFontColor,
                                        ),
                                        decoration: const InputDecoration(
                                            counterStyle: TextStyle(
                                              height: 0.1,
                                            ),
                                            hintText: 'This card\'s word',
                                            hintStyle: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                                color: ThemeColors
                                                    .primaryFontColor),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12)),
                                            )),
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        padding: const EdgeInsets.only(top: 16),
                                        icon: const Icon(
                                            Icons.translate_outlined),
                                        color: ThemeColors.secondaryFontColor,
                                        iconSize: 30,
                                        onPressed: () {
                                          isModelDownloaded
                                              ? translateText(
                                                      nativeTextController.text,
                                                      nativeLanguage,
                                                      localLanguage)
                                                  .then((value) => {
                                                        localTextController
                                                            .text = value
                                                      })
                                              :
                                              // Show snackbar saying the model is not downloaded
                                              showCustomSnackBar(
                                                  'Model not downloaded yet',
                                                  2,
                                                );
                                        },
                                      ),
                                    )
                                  ],
                                ),
                                const Spacer(),
                                // Hint
                                AutoSizeTextField(
                                  maxLines: 3,
                                  minLines: 1,
                                  maxLength: 100,
                                  minFontSize: 16,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: nativeNoteController,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeColors.secondaryFontColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r"\n"))
                                  ],
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.only(
                                          top: 16, left: 16, right: 16),
                                      counter: Offstage(),
                                      hintText: 'More details or a hint',
                                      hintStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              ThemeColors.secondaryFontColor),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      )),
                                ),
                                const Spacer(
                                  flex: 2,
                                ),
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
                      color: ThemeColors.primaryColor,
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                cursorColor: ThemeColors
                                    .primaryWhiteFontColor, // White cursor
                                // TODO: add to the theme
                                selectionColor: Colors
                                    .white24, // Light white selection background
                                selectionHandleColor: ThemeColors
                                    .primaryWhiteFontColor, // White selection handle
                              ),
                            ),
                            child: Column(
                              children: [
                                // Local text
                                AutoSizeTextField(
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: localTextController,
                                  minFontSize: 20,
                                  minLines: 1,
                                  maxLines: 2,
                                  maxLength: 50,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeColors.primaryWhiteFontColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r"\n"))
                                  ],
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                      counterStyle: TextStyle(
                                        color:
                                            ThemeColors.secondaryWhiteFontColor,
                                        height: 0.1,
                                      ),
                                      hintText: 'This card\'s translation',
                                      hintStyle: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeColors
                                              .primaryWhiteFontColor),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      )),
                                ),
                                const Spacer(),
                                // Romanization
                                AutoSizeTextField(
                                  maxLines: 3,
                                  minLines: 1,
                                  maxLength: 100,
                                  minFontSize: 16,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: localRomanizationController,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeColors.secondaryWhiteFontColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r"\n"))
                                  ],
                                  textInputAction: TextInputAction.done,
                                  cursorColor:
                                      ThemeColors.primaryWhiteFontColor,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.only(
                                        top: 16,
                                        left: 16,
                                        right: 16,
                                      ),
                                      counter: Offstage(),
                                      hintText: 'Romanization',
                                      hintStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeColors
                                              .secondaryWhiteFontColor),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      )),
                                ),
                                const Spacer(
                                  flex: 2,
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
                      child: IconButton(
                        disabledColor: ThemeColors.disabledColor,
                        color: ThemeColors.primaryColor,
                        onPressed: () { 
                          isButtonEnabled ? showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Discard changes?'),
                                content: const Text(
                                    'Are you sure you want to discard your changes?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Discard'),
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close the dialog
                                      Navigator.of(context).pop(); // Close the CardDialogView
                                    },
                                  ),
                                ],
                              );
                            },
                          ) : Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.clear,
                          size: 40,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        disabledColor: ThemeColors.disabledColor,
                        color: ThemeColors.primaryColor,
                        onPressed: isButtonEnabled
                            ? () {
                                if (widget.countryCard == null) {
                                  // Add the card into the database
                                  DatabaseHelper.instance
                                      .insertCard(
                                        CountryCard(
                                          countryId: widget.country.countryId!,
                                          nativeText: nativeTextController.text,
                                          nativeNote: nativeNoteController.text,
                                          localText: localTextController.text,
                                          localRomanization:
                                              localRomanizationController.text,
                                        ),
                                      )
                                      .then((newCardId) => {
                                            if (!widget
                                                     .countryDeck.isDefault! &&
                                                 newCardId != -1)
                                               {
                                                 DatabaseHelper.instance
                                                     .addCardToDeck(
                                                         widget.countryDeck
                                                             .countryDeckId!,
                                                         newCardId)
                                                     .then((value) => {}),
                                               }
                                           });
                                  // If the deck is not 'all cards', add the card to the deck
                                } else {
                                  // Edit the card
                                  DatabaseHelper.instance.updateCard(
                                    CountryCard(
                                      countryId:
                                          widget.countryCard!.countryId,
                                      countryCardId:
                                          widget.countryCard!.countryCardId,
                                      nativeText: nativeTextController.text,
                                      nativeNote: nativeNoteController.text,
                                      localText: localTextController.text,
                                      localRomanization:
                                          localRomanizationController.text,
                                    ),
    
                                  );
                                }
                                Navigator.of(context).pop();
                              }
                            : null,
                        icon: const Icon(
                          Icons.check,
                          size: 40,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          )),
    );
  }
}
