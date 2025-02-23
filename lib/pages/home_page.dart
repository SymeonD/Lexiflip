import 'package:cards/main.dart';
import 'package:cards/pages/language_decks_page.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:cards/utils/manage_language_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:canopas_country_picker/canopas_country_picker.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/ui/country_code_list_view.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Language> languages = [];
  String newLanguage = "";
  int columnCount = 2;
  int rowCount = 1;

  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  String? shakingLanguageCode; // Track which language is shaking

  final languageModelManager = OnDeviceTranslatorModelManager();

  late String nativeCountryCode;

  Future<void> checkNetworkAndPrompt(BuildContext context) async {
    var connectivityResult = await Connectivity().checkConnectivity();

    connectivityResult.contains(ConnectivityResult.wifi) ||
            connectivityResult.contains(ConnectivityResult.mobile)
        ? SharedPreferences.getInstance().then((prefs) {
            if (prefs.getBool("showLanguageDownloadPrompt") == null ||
                prefs.getBool("showLanguageDownloadPrompt")!) {
              // Get all the languages from the database
              var allLanguages =
                  languages.map((l) => l.languageCode).toSet().toList();
              // Add the native country code to the list of added languages
              allLanguages.add(nativeCountryCode);

              // Get the corresponding language codes
              allLanguages = allLanguages
                  .map((lang) => getLanguageCode(lang, context))
                  .toList();

              var notDownloadedLanguages = [];
              // Check if the languages are downloaded
              for (var languageCode in allLanguages) {
                languageModelManager
                    .isModelDownloaded(languageCode)
                    .then((value) => {
                          if (!value)
                            {
                              notDownloadedLanguages.add(languageCode),
                            }
                        });
              }
              if (notDownloadedLanguages.isNotEmpty && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Language downloading"),
                    content: Text(
                        "Some languages you are using $notDownloadedLanguages are not downloaded yet, do you want to download them now ? When done, you will be able to use automatic translation."),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            SharedPreferences.getInstance().then((prefs) {
                          prefs.setBool("showLanguageDownloadPrompt", false);
                          Navigator.pop(context);
                        }),
                        child: const Text("Never",
                            style: TextStyle(color: ThemeColors.deleteColor)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Not now"),
                      ),
                      TextButton(
                        onPressed: () {
                          for (var languageCode in notDownloadedLanguages) {
                            languageModelManager.downloadModel(languageCode,
                                isWifiRequired: false);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text("Yes"),
                      ),
                    ],
                  ),
                );
              }
            }
          })
        : null;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguages().then((value) => {
          checkNetworkAndPrompt(context),
        });

    SharedPreferences.getInstance().then((prefs) {
      nativeCountryCode = prefs.getString('nativeCountryCode') ?? "";
    });

    // Initialize the AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset(); // Reset after shaking
        }
      });
  }

  Future<bool> _loadLanguages() async {
    try {
      final db = DatabaseHelper.instance;
      var langList = await db.getLanguages();
      setState(() {
        languages = langList;
        columnCount = languages.length <= 5
            ? 2
            : languages.length <= 11
                ? 3
                : 4;
        rowCount = (languages.length / columnCount).ceil();
      });
      return true;
    } catch (e) {
      Logger().e("Error loading languages: $e");
      return false;
    }
  }

  void _triggerShake(String languageCode) {
    setState(() => shakingLanguageCode = languageCode);
    _controller.forward(); // Start the shake animation
  }

  void _showDeleteDialog() async {
    if (shakingLanguageCode == null) return;

    Language lang =
        languages.firstWhere((l) => l.languageCode == shakingLanguageCode);

    // Get the cards corresponding to the language
    var cards = await DatabaseHelper.instance
        .getCards(0, lang.languageId!, true); // 0 and true for all cards

    if (cards.isEmpty) {
      manageLanguageModel(getLanguageCode(lang.languageCode, context),
          ManageLanguageModelAction.DELETE);
      // Delete immediately if no cards exist
      await DatabaseHelper.instance.deleteLanguage(lang.languageId!);
      _loadLanguages();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Delete ${lang.languageName}?"),
          content: const Text(
              "This language has saved cards. Are you sure you want to delete it?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete",
                  style: TextStyle(color: ThemeColors.deleteColor)),
            ),
          ],
        ),
      ).then((value) => {
            if (value == true)
              {
                manageLanguageModel(getLanguageCode(lang.languageCode, context),
                    ManageLanguageModelAction.DELETE),
                DatabaseHelper.instance.deleteLanguage(lang.languageId!),
                _loadLanguages()
              }
          });
    }
    setState(() => shakingLanguageCode = null); // Reset the shaking effect
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("")),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Title(
                color: ThemeColors.primaryColor,
                child: const Text("Where are we going \n today ?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryColor)),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height *
                (switch (columnCount) {
                  2 => (0.3),
                  3 => 0.27,
                  4 => 0.2,
                  _ => 0.3,
                }),
            left: MediaQuery.of(context).size.width / 2 -
                MediaQuery.of(context).size.width * (columnCount * 0.1125),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width *
                        (columnCount * 0.225),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 90 / 60,
                      ),
                      itemCount: languages.length + 1,
                      itemBuilder: (context, index) {
                        if (index < languages.length) {
                          var lang = languages[index];
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: shakingLanguageCode == lang.languageCode
                                    ? Offset(_shakeAnimation.value, 0)
                                    : const Offset(0, 0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LanguageDecksPage(language: lang),
                                      ),
                                    );
                                  },
                                  onLongPress: () async => {
                                    _triggerShake(lang.languageCode),
                                    await languageModelManager
                                        .isModelDownloaded(getLanguageCode(
                                            lang.languageCode, context))
                                        .then((isModelDownloaded) => showMenu(
                                              context: context,
                                              position: _getPosition(context),
                                              color:
                                                  ThemeColors.backgroundColor,
                                              items: <PopupMenuEntry<String>>[
                                                PopupMenuItem<String>(
                                                  value: "download",
                                                  enabled: isModelDownloaded
                                                      ? false
                                                      : true,
                                                  child: IntrinsicWidth(
                                                    child: SizedBox(
                                                      width: 225,
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              isModelDownloaded
                                                                  ? Icons
                                                                      .file_download_off_outlined
                                                                  : Icons
                                                                      .file_download_outlined,
                                                              color: ThemeColors
                                                                  .primaryFontColor),
                                                          const SizedBox(
                                                              width: 10),
                                                          Text(isModelDownloaded
                                                              ? 'Language model downloaded'
                                                              : 'Download language model'),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const PopupMenuDivider(),
                                                const PopupMenuItem<String>(
                                                  value: "delete",
                                                  child: IntrinsicWidth(
                                                    child: SizedBox(
                                                      width: 100,
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete,
                                                              color: ThemeColors
                                                                  .deleteColor),
                                                          SizedBox(width: 10),
                                                          Text(
                                                            "Delete",
                                                            style: TextStyle(
                                                                color: ThemeColors
                                                                    .deleteColor),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ))
                                        .then((menuChoice) {
                                      if (menuChoice != null) {
                                        menuChoice == "download"
                                            ? manageLanguageModel(
                                                getLanguageCode(
                                                    lang.languageCode, context),
                                                ManageLanguageModelAction
                                                    .DOWNLOAD)
                                            : _showDeleteDialog();
                                      }
                                    })
                                  },
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: const Size(90, 60),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: CountryFlag.fromCountryCode(
                                    lang.languageCode,
                                    height: 60,
                                    width: 90,
                                    shape: const RoundedRectangle(10),
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () async {
                              final newLang = await showPickerDialog(context);
                              if (newLang != null) {
                                setState(() => newLanguage = newLang.name);
                                try {
                                  await DatabaseHelper.instance
                                      .insertLanguage(Language(
                                    languageCode: newLang.code,
                                    languageName: newLang.name,
                                  ));
                                  manageLanguageModel(
                                      getLanguageCode(newLang.code, context),
                                      ManageLanguageModelAction.DOWNLOAD);
                                  _loadLanguages();
                                } catch (e) {
                                  Logger().e("Error inserting language: $e");
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeColors.backgroundColor,
                              fixedSize: const Size(90, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child:
                                const Text("+", style: TextStyle(fontSize: 24)),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -140,
            child: SvgPicture.asset(
              "assets/img/planet-earth.svg",
              height: 420,
              width: 420,
            ),
          ),
          const Positioned(
              bottom: 225,
              left: 160,
              child: Icon(
                Icons.location_on_outlined,
                size: 75,
                color: Color(0xffF4581B), // TODO: add to theme ?
              ))
        ],
      ),
    );
  }

  RelativeRect _getPosition(BuildContext context) {
    final RenderBox bar = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        bar.localToGlobal(bar.size.bottomRight(Offset.zero), ancestor: overlay),
        bar.localToGlobal(bar.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    position = RelativeRect.fromLTRB(
      position.left, // Offset the position right by 5
      position.top + 3, // Offset the position down by 3
      position.right,
      position.bottom,
    );
    return position;
  }

  Future<CountryCode?> showPickerDialog(BuildContext context) async {
    // Add native country code to the list of added languages
    final addedLanguages = languages.map((lang) => lang.languageCode).toSet();
    addedLanguages.add(nativeCountryCode);
    return await showCountryCodePickerDialog(
      context: context,
      customizationBuilders: CustomizationBuilders(
        codeBuilder: (CountryCode code) {
          if (addedLanguages.contains(code.code)) {
            return const SizedBox();
          }
          return DefaultCountryCodeListItemView(
            code: code,
          );
        },
        countryListBuilder: (codes, controller) {
          final filteredCodes = codes
              .where((code) => !addedLanguages.contains(code.code))
              .toList();
          return CountryCodeListView(
              codes: filteredCodes, controller: controller);
        },
      ),
    );
  }
}
