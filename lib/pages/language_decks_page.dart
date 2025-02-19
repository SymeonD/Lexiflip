import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/ui/deck_dialog_view.dart';
import 'package:cards/ui/language_deck_view.dart';
import 'package:cards/ui/search_bar_view.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

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
    return Scaffold(
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
                  widget.language.languageName,
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
                        color: Colors.white,
                        child: const Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
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
