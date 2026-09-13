import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/country.dart';
import 'package:cards/models/country_card.dart';
import 'package:cards/models/country_deck.dart';
import 'package:cards/ui/search_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class DeckDialogView extends StatefulWidget {
  final Country country;
  // For editing an existing deck
  final CountryDeck? countryDeck;
  // Callback to reload the decks
  final VoidCallback onEdit;
  const DeckDialogView(
      {super.key,
      required this.country,
      this.countryDeck,
      required this.onEdit});

  @override
  State createState() => _DeckDialogViewState();
}

class _DeckDialogViewState extends State<DeckDialogView> {
  late TextEditingController deckNameController;
  late TextEditingController searchController;
  late ScrollController scrollController;
  bool _isButtonEnabled = false;

  List<CountryCardSelection> cardsWithSelection = [];
  List<CountryCardSelection> filteredCards = [];
  List<CountryCard?> deckCards = [];

  @override
  void initState() {
    deckNameController = TextEditingController();
    searchController = TextEditingController();
    scrollController = ScrollController();
    if (widget.countryDeck != null) {
      deckNameController.text = widget.countryDeck!.countryDeckName;
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
    widget.onEdit();
    super.dispose();
  }

  // Load all cards linked to the country
  Future<void> _loadCards() async {
    try {
      final db = DatabaseHelper.instance;
      var cardList = await db.getCards(
          0, widget.country.countryId!, true); // Get all cards (default deck)
      if (widget.countryDeck != null && !widget.countryDeck!.isDefault!) {
        // Get all the cards linked to the deck
        deckCards = await db.getCards(
            widget.countryDeck!.countryDeckId!, widget.country.countryId!);
        setState(() {
          cardsWithSelection = cardList
              .map((card) => CountryCardSelection(
                  card: card,
                  isSelected: deckCards
                      .whereType<CountryCard>()
                      .map((card) => card.countryCardId)
                      .contains(card?.countryCardId)))
              .toList();
          _filter(searchController.text);
        });
      } else {
        setState(() {
          cardsWithSelection = cardList
              .map((card) =>
                  CountryCardSelection(card: card, isSelected: false))
              .toList();
          _filter(searchController.text);
        });
      }
    } catch (e) {
      Logger().e("Error loading countries: $e");
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
              hintText: widget.countryDeck != null
                  ? widget.countryDeck!.countryDeckName
                  : 'What is this deck about ?',
              icon: Icons.book_outlined,
              inputMaxLength: 20,
            ),
            const SizedBox(
                width: 150, child: Divider(height: 1, color: Colors.grey)),
            const SizedBox(height: 20),
            SearchBarView(
                searchController: searchController,
                hintText: widget.countryDeck != null
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
                  color: ThemeColors.primaryColor,
                  onPressed: _isButtonEnabled
                      ? () async {
                          if (widget.countryDeck != null) {
                            await DatabaseHelper.instance.updateDeckName(
                                widget.countryDeck!.countryDeckId!,
                                deckNameController.text);

                            for (var card in filteredCards) {
                              bool wasSelected = deckCards
                                  .whereType<CountryCard>()
                                  .map((c) => c.countryCardId)
                                  .contains(card.card!.countryCardId);

                              if (card.isSelected != wasSelected) {
                                if (card.isSelected) {
                                  await DatabaseHelper.instance.addCardToDeck(
                                      widget.countryDeck!.countryDeckId!,
                                      card.card!.countryCardId!);
                                } else {
                                  await DatabaseHelper.instance
                                      .removeCardFromDeck(
                                          widget.countryDeck!.countryDeckId!,
                                          card.card!.countryCardId!);
                                }
                              }
                            }
                          } else {
                            int newDeckId = await DatabaseHelper.instance
                                .insertDeck(widget.country.countryId!,
                                    deckNameController.text);
                            for (var card
                                in filteredCards.where((c) => c.isSelected)) {
                              await DatabaseHelper.instance.addCardToDeck(
                                  newDeckId, card.card!.countryCardId!);
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

class CountryCardSelection {
  CountryCard? card;
  bool isSelected;

  CountryCardSelection({required this.card, this.isSelected = false});
}
