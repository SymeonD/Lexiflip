import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/country.dart';
import 'package:cards/models/country_deck.dart';
import 'package:cards/ui/deck_dialog_view.dart';
import 'package:cards/ui/country_deck_view.dart';
import 'package:cards/ui/deck_receiving_view.dart';
import 'package:cards/ui/search_bar_view.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:logger/web.dart';

class CountryDecksPage extends StatefulWidget {
  final Country country;
  const CountryDecksPage({super.key, required this.country});

  @override
  State createState() => _CountryDecksPageState();
}

class _CountryDecksPageState extends State<CountryDecksPage> {
  List<CountryDeck> decks = [];
  List<CountryDeck> filteredDecks = [];
  Map<int, int> deckCardCounts = {}; // Map to hold deckId and its card count
  final searchController = TextEditingController();
  bool isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _loadCountryDecks();
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
            .where((deck) => deck.countryDeckName
                .toLowerCase()
                .contains(filterText.toLowerCase()))
            .toList();
      }
    });
  }

  // Load all the country decks for the given country code
  Future<void> _loadCountryDecks() async {
    try {
      final db = DatabaseHelper.instance;
      var deckList = await db.getDecks(widget.country.countryId!);
      // If there is no decks, create a new one
      if (deckList.isEmpty) {
        await db.insertDeck(widget.country.countryId!, 'All cards',
            true); // True because default deck
        deckList = await db.getDecks(widget.country.countryId!);
      }

      final counts = <int, int>{};
      for (var deck in deckList) {
        final count = await db.getDeckCardCount(
            deck.countryDeckId!, deck.isDefault!, widget.country.countryId!);
        counts[deck.countryDeckId!] = count;
      }

      setState(() {
        decks = deckList;
        deckCardCounts = counts;
        _filter(searchController.text);
      });
    } catch (e) {
      Logger().e("Error loading decks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ThemeColors.backgroundColor,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 5, left: 8),
          child: Row(
            children: [
              CountryFlag.fromCountryCode(
                widget.country.countryCode,
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
                  widget.country.countryName,
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
          // Create a list view of the country decks
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
                  return CountryDeckView(
                    country: widget.country,
                    countryDeck: filteredDecks[index],
                    deckCardCount: deckCardCounts[filteredDecks[index].countryDeckId!] ?? 0,
                    onEdit: _loadCountryDecks,
                  );
                } else {
                  return InkWell(
                    splashColor: Colors.transparent,
                    onTap: () async {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return DeckDialogView(
                              country: widget.country,
                              onEdit: _loadCountryDecks,
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
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return DeckReceivingView(
                                              country: widget.country,
                                              onDeckReceived: _loadCountryDecks,
                                            );
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
