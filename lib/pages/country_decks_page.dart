import 'dart:convert';

import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/country.dart';
import 'package:cards/models/country_card.dart';
import 'package:cards/models/country_deck.dart';
import 'package:cards/ui/deck_dialog_view.dart';
import 'package:cards/ui/country_deck_view.dart';
import 'package:cards/ui/search_bar_view.dart';
import 'package:cards/utils/handle_share_permissions.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:logger/web.dart';
import 'package:nearby_connections/nearby_connections.dart';

class LanguageDecksPage extends StatefulWidget {
  final Language language;
  const LanguageDecksPage({super.key, required this.language});

  @override
  State createState() => _LanguageDecksPageState();
}

class _LanguageDecksPageState extends State<LanguageDecksPage> {
  List<LanguageDeck> decks = [];
  List<LanguageDeck> filteredDecks = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLanguageDecks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filter(String filterText) {
    setState(() {
      if (filterText.trim().isEmpty) {
        filteredDecks = decks;
      } else {
        filteredDecks = decks
            .where((deck) => deck.languageDeckName
                .toLowerCase()
                .contains(filterText.toLowerCase()))
            .toList();
      }
    });
  }

  // Load all the language decks for the given language code
  Future<void> _loadLanguageDecks() async {
    try {
      final db = DatabaseHelper.instance;
      var deckList = await db.getDecks(widget.language.languageId!);
      // If there is no decks, create a new one
      if (deckList.isEmpty) {
        await db.insertDeck(widget.language.languageId!, 'All cards',
            true); // True because default deck
        deckList = await db.getDecks(widget.language.languageId!);
      }
      setState(() {
        decks = deckList;
        _filter(searchController.text);
      });
    } catch (e) {
      Logger().e("Error loading decks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDiscovering = false;
    const String userName = "LexiFlip";
    const Strategy strategy = Strategy.P2P_STAR;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ThemeColors.backgroundColor,
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
                  widget.language.languageName,
                  overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                  maxLines: 1, // Limit to one line
                  style: const TextStyle(
                    color: ThemeColors.primaryFontColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          // Create a list view of the language decks
          Column(children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
          child: SearchBarView(
              searchController: searchController,
              hintText: "Search Deck",
              onChanged: _filter),
        ),
        Expanded(
          child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 90 / 140, // Adjust the aspect ratio
              ),
              padding: const EdgeInsets.all(8),
              itemCount: filteredDecks.length + 1,
              itemBuilder: (context, index) {
                if (index < filteredDecks.length) {
                  return LanguageDeckView(
                    language: widget.language,
                    languageDeck: filteredDecks[index],
                    onDelete: _loadLanguageDecks,
                  );
                } else {
                  return InkWell(
                    splashColor: Colors.transparent,
                    onTap: () async {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return DeckDialogView(
                              language: widget.language,
                              onDelete: _loadLanguageDecks,
                            );
                          });
                    },
                    child: SizedBox(
                      width: 200,
                      height: 500, // Define the height of the container here
                      child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        color: ThemeColors.backgroundColor,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.download_outlined,
                                      color: ThemeColors.secondaryFontColor,
                                      size: 30,
                                    ),
                                    onPressed: () async {
                                      if (isDiscovering) return;
                                      await handleShare(context);

                                      isDiscovering = true;

                                      Future.delayed(
                                          const Duration(seconds: 30), () {
                                        Nearby().stopDiscovery();
                                        isDiscovering = false;
                                        showCustomSnackBar(
                                            "Discovery stopped", 2);
                                      });

                                      await Nearby().startDiscovery(
                                          userName, strategy, onEndpointFound:
                                              (id, name, serviceId) {
                                        showCustomSnackBar(
                                            "endpoint found $name", 2);
                                        // Optionally initiate connection here:
                                        Nearby().requestConnection(userName, id,
                                            onConnectionInitiated: (id, info) {
                                          Nearby().acceptConnection(id,
                                              onPayLoadRecieved:
                                                  (endpointId, payload) async {
                                            // Create a new deck from the payload
                                            final data =
                                                utf8.decode(payload.bytes!);
                                            final jsonData = jsonDecode(data);
                                            final deckName =
                                                jsonData["deck"]["deckName"];
                                            final languageId =
                                                jsonData["deck"]["languageId"];
                                            // Add the deck to the database
                                            await DatabaseHelper.instance
                                                .insertDeck(
                                                    languageId, deckName)
                                                .then((deckId) => {
                                                      jsonData["cards"]
                                                          .forEach((card) {
                                                        Logger()
                                                            .i("Card: $card");
                                                        DatabaseHelper.instance
                                                            .insertCard(LanguageCard(
                                                                languageId:
                                                                    languageId,
                                                                nativeText: card[
                                                                    "nativeText"],
                                                                nativeNote: card[
                                                                    "nativeNote"],
                                                                localText: card[
                                                                    "localText"],
                                                                localRomanization:
                                                                    card[
                                                                        "localRomanization"]))
                                                            .then((cardId) => {
                                                                  DatabaseHelper
                                                                      .instance
                                                                      .addCardToDeck(
                                                                          deckId,
                                                                          cardId)
                                                                });
                                                      }),
                                                    });

                                            // Reload the page
                                            _loadLanguageDecks();

                                            showCustomSnackBar(
                                                "Payload received: ${payload.toString()}",
                                                2);
                                          }, onPayloadTransferUpdate:
                                                  (endpointId, update) {
                                            // Handle progress or completion here
                                          });

                                          showCustomSnackBar(
                                              "connection initiated", 2);
                                        }, onConnectionResult: (id, status) {
                                          if (status == Status.CONNECTED) {
                                            showCustomSnackBar(
                                                "Connection successful", 2);
                                          } else {
                                            showCustomSnackBar(
                                                "Connection failed", 2);
                                          }
                                        }, onDisconnected: (id) {
                                          showCustomSnackBar("Disconnected", 2);
                                          // Stop discovery if needed
                                          Nearby().stopDiscovery();
                                          isDiscovering = false;
                                        });
                                      }, onEndpointLost: (id) {
                                        showCustomSnackBar("Endpoint lost", 2);
                                        Nearby().stopDiscovery();
                                        isDiscovering = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Center(
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeColors.secondaryFontColor,
                                  ),
                                ),
                              ),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  //empty space
                                  SizedBox(
                                    height: 50,
                                  ),
                                ],
                              ),
                            ]),
                      ),
                    ),
                  );
                }
              }),
        ),
      ]),
    );
  }
}
