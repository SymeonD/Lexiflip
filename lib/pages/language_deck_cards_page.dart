import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/ui/card_dialog_view.dart';
import 'package:cards/ui/language_card_view.dart';
import 'package:cards/ui/search_bar_view.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LanguageCardPage extends StatefulWidget {
  final Language language;
  final LanguageDeck languageDeck;
  final VoidCallback onCardEdited;
  const LanguageCardPage(
      {super.key,
      required this.language,
      required this.languageDeck,
      required this.onCardEdited});

  @override
  State createState() => _LanguageCardPageState();
}

class _LanguageCardPageState extends State<LanguageCardPage> {
  List<LanguageCard?> cards = [];
  List<LanguageCard?> filteredCards = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeckCards();
  }

  @override
  void dispose() {
    widget.onCardEdited();
    searchController.dispose();
    super.dispose();
  }

  void _filter(String filterText) {
    setState(() {
      if (filterText.trim().isEmpty) {
        filteredCards = cards;
      } else {
        filteredCards = cards
            .where((card) => card!.nativeText
                .toLowerCase()
                .contains(filterText.toLowerCase()))
            .toList();
      }
    });
  }

  // Load the deck cards
  Future<void> _loadDeckCards() async {
    try {
      final db = DatabaseHelper.instance;
      var cardList = await db.getCards(widget.languageDeck.languageDeckId!,
          widget.language.languageId!, widget.languageDeck.isDefault!);
      setState(() {
        cards = cardList;
        _filter(searchController.text);
      });
    } catch (e) {
      Logger().e("Error loading cards: $e");
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
          Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
            child: SearchBarView(
                searchController: searchController,
                hintText: 'Search Card',
                onChanged: _filter),
          ),
          Expanded(
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 90 / 60, // Adjust the aspect ratio
                ),
                padding: const EdgeInsets.all(8),
                itemCount: filteredCards.length + 1,
                itemBuilder: (context, index) {
                  if (index < filteredCards.length) {
                    return LanguageCardView(
                      language: widget.language,
                      languageCard: filteredCards[index]!,
                      languageDeck: widget.languageDeck,
                      onDelete: _loadDeckCards,
                    );
                  } else {
                    return InkWell(
                      splashColor: Colors.transparent,
                      onTap: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CardDialogView(
                                    language: widget.language,
                                    languageDeck: widget.languageDeck,
                                    onCardAdded: _loadDeckCards,
                                    cardTag: "default")));
                      },
                      child: Hero(
                        tag: 'default',
                        child: SizedBox(
                          width: 200,
                          height:
                              150, // Define the height of the container here

                          child: Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            color: ThemeColors.backgroundColor,
                            child: const Center(
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.secondaryFontColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }),
          ),
        ],
      ),
    );
  }
}
