import 'package:cards/main.dart';
import 'package:cards/pages/country_decks_page.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:cards/utils/manage_country_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:canopas_country_picker/canopas_country_picker.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/country.dart';
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
  List<Country> countries = [];
  String newCountry = "";
  int columnCount = 2;
  int rowCount = 1;

  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  String? shakingCountryCode; // Track which country is shaking

  final countryModelManager = OnDeviceTranslatorModelManager();

  late String nativeCountryCode;

  Future<void> checkNetworkAndPrompt(BuildContext context) async {
    var connectivityResult = await Connectivity().checkConnectivity();

    connectivityResult.contains(ConnectivityResult.wifi) ||
            connectivityResult.contains(ConnectivityResult.mobile)
        ? SharedPreferences.getInstance().then((prefs) {
            if (prefs.getBool("showCountryDownloadPrompt") == null ||
                prefs.getBool("showCountryDownloadPrompt")!) {
                  
              // Get the corresponding language codes
              var allCountries = countries
                  .map((c) => c.countryLanguageCode)
                  .toSet()
                  .toList();

              allCountries.add(getLanguageCode(nativeCountryCode));

              var notDownloadedCountries = [];
              // Check if the countries are downloaded
              for (var countryCode in allCountries) {
                countryModelManager
                    .isModelDownloaded(countryCode)
                    .then((value) => {
                          if (!value)
                            {
                              notDownloadedCountries.add(countryCode),
                            }
                        });
              }
              if (notDownloadedCountries.isNotEmpty && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Country downloading"),
                    content: Text(
                        "Some countries you are using $notDownloadedCountries are not downloaded yet, do you want to download them now ? When done, you will be able to use automatic translation."),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            SharedPreferences.getInstance().then((prefs) {
                          prefs.setBool("showCountryDownloadPrompt", false);
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
                          for (var countryCode in notDownloadedCountries) {
                            countryModelManager.downloadModel(countryCode,
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
    _loadCountries().then((value) => {
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

  Future<bool> _loadCountries() async {
    try {
      final db = DatabaseHelper.instance;
      var countryList = await db.getCountries();
      setState(() {
        countries = countryList;
        columnCount = countries.length <= 5
            ? 2
            : countries.length <= 11
                ? 3
                : 4;
        rowCount = (countries.length / columnCount).ceil();
      });
      return true;
    } catch (e) {
      Logger().e("Error loading countries: $e");
      return false;
    }
  }

  void _triggerShake(String countryCode) {
    setState(() => shakingCountryCode = countryCode);
    _controller.forward(); // Start the shake animation
  }

  void _showDeleteDialog() async {
    if (shakingCountryCode == null) return;

    Country country =
        countries.firstWhere((c) => c.countryCode == shakingCountryCode);

    // Get the cards corresponding to the country
    var cards = await DatabaseHelper.instance
        .getCards(0, country.countryId!, true); // 0 and true for all cards

    if (cards.isEmpty) {
      manageCountryModel(country.countryLanguageCode,
          ManageCountryModelAction.DELETE);
      // Delete immediately if no cards exist
      await DatabaseHelper.instance.deleteCountry(country.countryId!);
      _loadCountries();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Delete ${country.countryName}?"),
          content: const Text(
              "This country has saved cards. Are you sure you want to delete it?"),
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
                manageCountryModel(country.countryLanguageCode,
                    ManageCountryModelAction.DELETE),
                DatabaseHelper.instance.deleteCountry(country.countryId!),
                _loadCountries()
              }
          });
    }
    setState(() => shakingCountryCode = null); // Reset the shaking effect
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
                      itemCount: countries.length + 1,
                      itemBuilder: (context, index) {
                        if (index < countries.length) {
                          var country = countries[index];
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: shakingCountryCode == country.countryCode
                                    ? Offset(_shakeAnimation.value, 0)
                                    : const Offset(0, 0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CountryDecksPage(country: country),
                                      ),
                                    );
                                  },
                                  onLongPress: () async => {
                                    _triggerShake(country.countryCode),
                                    await countryModelManager
                                        .isModelDownloaded(country.countryLanguageCode)
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
                                            ? manageCountryModel(
                                                country.countryLanguageCode,
                                                ManageCountryModelAction
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
                                    country.countryCode,
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
                              final newCount = await showPickerDialog(context);
                              if (newCount != null) {
                                setState(() => newCountry = newCount.name);
                                final newCountLangCode = getLanguageCode(newCount.code);
                                try {
                                  await DatabaseHelper.instance
                                      .insertCountry(Country(
                                    countryCode: newCount.code,
                                    countryName: newCount.name,
                                    countryLanguageCode: newCountLangCode,
                                  ));
                                  manageCountryModel(
                                      newCountLangCode,
                                      ManageCountryModelAction.DOWNLOAD);
                                  _loadCountries();
                                } catch (e) {
                                  Logger().e("Error inserting country: $e");
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
    // Add native country code to the list of added countries
    final addedCountries = countries.map((country) => country.countryCode).toSet();
    addedCountries.add(nativeCountryCode);
    return await showCountryCodePickerDialog(
      context: context,
      customizationBuilders: CustomizationBuilders(
        codeBuilder: (CountryCode code) {
          if (addedCountries.contains(code.code)) {
            return const SizedBox();
          }
          return DefaultCountryCodeListItemView(
            code: code,
          );
        },
        countryListBuilder: (codes, controller) {
          final filteredCodes = codes
              .where((code) => !addedCountries.contains(code.code))
              .toList();
          return CountryCodeListView(
              codes: filteredCodes, controller: controller);
        },
      ),
    );
  }
}
