import 'dart:isolate';

import 'package:cards/pages/language_decks_page.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:cards/utils/manage_language_model.dart';
import 'package:flutter/material.dart';
import 'package:canopas_country_picker/canopas_country_picker.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/ui/country_code_list_view.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLanguages();

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
          _showDeleteDialog();
        }
      });
  }

  Future<void> _loadLanguages() async {
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
    } catch (e) {
      Logger().e("Error loading languages: $e");
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

    if (lang.languageCards == null || lang.languageCards!.isEmpty) {
      manageLanguageModel(
          getLanguageCode(lang.languageCode), ManageLanguageModelAction.DELETE);
      // Delete immediately if no cards exist
      await DatabaseHelper.instance.deleteLanguage(lang.languageId!);
      _loadLanguages();
    } else {
      bool? confirmDelete = await showDialog(
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
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        manageLanguageModel(getLanguageCode(lang.languageCode),
            ManageLanguageModelAction.DELETE);

        await DatabaseHelper.instance.deleteLanguage(lang.languageId!);
        _loadLanguages();
      }
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
                color: Theme.of(context).colorScheme.primary,
                child: const Text("Where are we going \n today ?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1EA6C6))),
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
                                  onLongPress: () =>
                                      _triggerShake(lang.languageCode),
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
                                  _loadLanguages();
                                } catch (e) {
                                  Logger().e("Error inserting language: $e");
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
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
                color: Color(0xffF4581B),
              ))
        ],
      ),
    );
  }

  Future<CountryCode?> showPickerDialog(BuildContext context) async {
    final addedLanguages = languages.map((lang) => lang.languageCode).toSet();
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
