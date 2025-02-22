import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/ui/search_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class DeckDialogView extends StatefulWidget {
  final Language language;
  // For editing an existing deck
  final LanguageDeck? languageDeck;
  // Callback to reload the decks
  final VoidCallback onDelete;
  const DeckDialogView(
      {super.key,
      required this.language,
      this.languageDeck,
      required this.onDelete});

  @override
  State createState() => _DeckDialogViewState();
}

class _DeckDialogViewState extends State<DeckDialogView> {
  late TextEditingController deckNameController;
  late TextEditingController searchController;
  late ScrollController scrollController;
  bool _isButtonEnabled = false;

  List<LanguageCardSelection> cardsWithSelection = [];
  List<LanguageCardSelection> filteredCards = [];
  List<LanguageCard?> deckCards = [];

  @override
  void initState() {
    deckNameController = TextEditingController();
    searchController = TextEditingController();
    scrollController = ScrollController();
    if (widget.languageDeck != null) {
      deckNameController.text = widget.languageDeck!.languageDeckName;
    }
    deckNameController.addListener(() {
      setState(() {
        _filter("");
        _isButtonEnabled = deckNameController.text.isNotEmpty;
      });
    });
    _loadCards();
    super.initState();
  }

  @override
  void dispose() {
    deckNameController.dispose();
    searchController.dispose();
    scrollController.dispose();
    widget.onDelete();
    super.dispose();
  }

  // Load all cards linked to the language
  Future<void> _loadCards() async {
    try {
      final db = DatabaseHelper.instance;
      var cardList = await db.getCards(
          0, widget.language.languageId!, true); // Get all cards (default deck)
      if (widget.languageDeck != null && !widget.languageDeck!.isDefault!) {
        // Get all the cards linked to the deck
        deckCards = await db.getCards(
            widget.languageDeck!.languageDeckId!, widget.language.languageId!);
        setState(() {
          cardsWithSelection = cardList
              .map((card) => LanguageCardSelection(
                  card: card,
                  isSelected: deckCards
                      .whereType<LanguageCard>()
                      .map((card) => card.languageCardId)
                      .contains(card?.languageCardId)))
              .toList();
          _filter(searchController.text);
        });
      } else {
        setState(() {
          cardsWithSelection = cardList
              .map((card) =>
                  LanguageCardSelection(card: card, isSelected: false))
              .toList();
          _filter(searchController.text);
        });
      }
    } catch (e) {
      Logger().e("Error loading languages: $e");
    }
  }

  void _filter(String filterText) {
    setState(() {
      if (filterText.trim().isEmpty) {
        filteredCards = cardsWithSelection;
      } else {
        filteredCards = cardsWithSelection
            .where(
              (element) =>
                  element.card!.nativeText
                      .toLowerCase()
                      .startsWith(filterText.trim().toLowerCase()) ||
                  element.card!.nativeText
                      .toLowerCase()
                      .contains(filterText.trim().toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // title: const Text('Create new deck'),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            SearchBarView(
              searchController: deckNameController,
              hintText: widget.languageDeck != null
                  ? widget.languageDeck!.languageDeckName
                  : 'What is this deck about ?',
              icon: Icons.book_outlined,
              inputMaxLength: 20,
            ),
            const SizedBox(
                width: 150, child: Divider(height: 1, color: Colors.grey)),
            const SizedBox(height: 20),
            SearchBarView(
                searchController: searchController,
                hintText: widget.languageDeck != null
                    ? 'Search Card Name'
                    : 'Add existing cards',
                onChanged: _filter),
            const SizedBox(height: 8),
            // Scrollable list of cards goes here
            SizedBox(
              height: 200,
              child: Scrollbar(
                interactive: true,
                controller: scrollController,
                child: ListView.separated(
                    controller: scrollController,
                    padding: MediaQuery.of(context).padding,
                    itemCount: filteredCards.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 0),
                    itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          setState(() {
                            filteredCards[index].isSelected =
                                !filteredCards[index].isSelected;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                    filteredCards[index].card!.nativeText,
                                    style: const TextStyle(fontSize: 16)),
                              ),
                              SizedBox(
                                height: 40,
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: filteredCards[index].isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        _isButtonEnabled = true;
                                        filteredCards[index].isSelected = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  disabledColor: Colors.grey,
                  color: const Color(0xff1EA6c6),
                  onPressed: _isButtonEnabled
                      ? () async {
                          if (widget.languageDeck != null) {
                            await DatabaseHelper.instance.updateDeckName(
                                widget.languageDeck!.languageDeckId!,
                                deckNameController.text);

                            for (var card in filteredCards) {
                              bool wasSelected = deckCards
                                  .whereType<LanguageCard>()
                                  .map((c) => c.languageCardId)
                                  .contains(card.card!.languageCardId);

                              if (card.isSelected != wasSelected) {
                                if (card.isSelected) {
                                  await DatabaseHelper.instance.addCardToDeck(
                                      widget.languageDeck!.languageDeckId!,
                                      card.card!.languageCardId!);
                                } else {
                                  await DatabaseHelper.instance
                                      .removeCardFromDeck(
                                          widget.languageDeck!.languageDeckId!,
                                          card.card!.languageCardId!);
                                }
                              }
                            }
                          } else {
                            int newDeckId = await DatabaseHelper.instance
                                .insertDeck(widget.language.languageId!,
                                    deckNameController.text);
                            for (var card
                                in filteredCards.where((c) => c.isSelected)) {
                              await DatabaseHelper.instance.addCardToDeck(
                                  newDeckId, card.card!.languageCardId!);
                            }
                          }
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(
                    Icons.check,
                    size: 30,
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class LanguageCardSelection {
  LanguageCard? card;
  bool isSelected;

  LanguageCardSelection({required this.card, this.isSelected = false});
}
