import 'package:canopas_country_picker/canopas_country_picker.dart';
import 'package:cards/pages/home_page.dart';
import 'package:cards/ui/country_code_list_view.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartingPage extends StatefulWidget {
  const StartingPage({super.key});

  @override
  State createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> {
  late CountryCode countryCode;
  bool selected = false;
  late TextEditingController textEditingController;

  final languageModel = OnDeviceTranslatorModelManager();

  @override
  void initState() {
    textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(""), // ("Choose your language"),
      ),
      body: Stack(children: [
        Center(
            child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 80),
                    Title(
                      color: Theme.of(context).colorScheme.primary,
                      child: const Text("Where do you come from ?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 75),
                    TextField(
                      readOnly: true,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        // label: const Text("Select country"),
                        // labelStyle: kTextStyle,
                        suffixIcon: !selected
                            ? const Icon(Icons.arrow_drop_down_rounded)
                            : const Icon(Icons.arrow_drop_up_rounded),
                        isDense: true,
                        filled: true,
                        contentPadding: const EdgeInsets.all(15),
                        hintText: "Select country",
                        hintStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onTap: () async {
                        setState(() {
                          selected = !selected;
                        });
                        final code = await showPickerSheet(context);
                        setState(() {
                          if (code != null) {
                            textEditingController.text =
                                "${code.flag}   ${code.name}";
                            countryCode = code;
                          }
                          selected = !selected;
                        });
                      },
                    ),
                  ],
                ),
                // Elevated button at the bottom right of the screen
                IconButton(
                  onPressed: () {
                    // ignore: unnecessary_null_comparison
                    countryCode != null
                        ? {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setString(
                                  "nativeCountryCode", countryCode.code);
                              //TODO: Snackbar error when getLanguageCode returns 'en' because unknown
                              prefs.setString("nativeLanguageCode",
                                  getLanguageCode(countryCode.code)!);
                              //TODO: Snackbar while model is downloading
                              languageModel
                                  .downloadModel(
                                      getLanguageCode(countryCode.code)!)
                                  .then((value) => {
                                        languageModel
                                            .isModelDownloaded(getLanguageCode(
                                                countryCode.code)!)
                                            .then((value) => {
                                                  Logger().d(
                                                      "Model ${countryCode.code} downloaded: $value")
                                                })
                                      });
                            }),
                          }
                        : null;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.check,
                    color: Color(0xff1EA6c6),
                    size: 40,
                  ),
                ),
              ]),
        )),
        Positioned(
          bottom: -100,
          left: -150,
          child: SvgPicture.asset(
            "assets/img/planet-earth.svg",
            height: 350,
            width: 350,
          ),
        ),
      ]),
    );
  }

  Future<CountryCode?> showPickerSheet(BuildContext context) async {
    return await showCountryCodePickerSheet(
      context: context,
      customizationBuilders: CustomizationBuilders(
        codeBuilder: (CountryCode code) {
          return DefaultCountryCodeListItemView(
            code: code,
            onCountryCodeTap: () {
              setState(() {
                textEditingController.text = "${code.flag}   ${code.name}";
              });
              Navigator.pop(context);
            },
          );
        },
        countryListBuilder: (codes, controller) => CountryCodeListView(
          codes: codes,
          controller: controller,
        ),
      ),
    );
  }
}
