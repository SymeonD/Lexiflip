import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
// import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/ui/card_dialog_view.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:flutter/material.dart';

class LanguageCardView extends StatefulWidget {
  // final Language language;
  final LanguageCard languageCard;
  final Language language;

  // OnDelete
  final VoidCallback onDelete;

  // Edit
  final LanguageDeck languageDeck;

  const LanguageCardView(
      {super.key,
      // required this.language,
      required this.languageCard,
      required this.onDelete,
      required this.languageDeck,
      required this.language});

  @override
  State createState() => _LanguageCardViewState();
}

class _LanguageCardViewState extends State<LanguageCardView> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return CardDialogView(
            language: widget.language,
            languageCard: widget.languageCard,
            onCardAdded: widget.onDelete,
            languageDeck: widget.languageDeck,
            cardTag: widget.languageCard.languageCardId.toString(),
          );
        }));
      },
      child: Hero(
        tag: widget.languageCard.languageCardId.toString(),
        child: SizedBox(
          width: 200,
          height: 150, // Define the height of the container here
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        // Handle menu selection
                        if (value == "edit") {
                          // TODO: See if kept here ?
                          // Open the page to edit the card
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return CardDialogView(
                              language: widget.language,
                              languageCard: widget.languageCard,
                              onCardAdded: widget.onDelete,
                              languageDeck: widget.languageDeck,
                              cardTag:
                                  widget.languageCard.languageCardId.toString(),
                            );
                          }));
                        } else if (value == "share") {
                          // Share the deck
                          // Show a bar at the bottom of the screen with a text 'Coming soon'
                          showCustomSnackBar(context, "Coming soon", 2);
                        } else if (value == "remove") {
                          // Remove the card from the deck
                          DatabaseHelper.instance.removeCardFromDeck(
                            widget.languageDeck.languageDeckId!,
                            widget.languageCard.languageCardId!,
                          );
                          widget.onDelete();
                        } else if (value == "delete") {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Delete card"),
                                  content: const Text(
                                      "Are you sure you want to delete this card?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("Delete"),
                                      onPressed: () {
                                        DatabaseHelper.instance.deleteCard(
                                          widget.languageCard.languageCardId!,
                                        );
                                        widget.onDelete();
                                        // Delete the card
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              });
                        }
                      },
                      offset: const Offset(0, 40),
                      color: Colors.white,
                      icon: const Icon(Icons.more_horiz),
                      itemBuilder: (BuildContext context) => [
                        // Edit option
                        const PopupMenuItem(
                          value: "edit",
                          height: 35,
                          padding: EdgeInsets.only(left: 10),
                          child: IntrinsicWidth(
                            child: SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      color: Colors.black),
                                  SizedBox(width: 10),
                                  Text("Edit"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Share option
                        const PopupMenuItem(
                          value: "share",
                          height: 35,
                          child: IntrinsicWidth(
                            child: SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined,
                                      color: Colors.black),
                                  SizedBox(width: 10),
                                  Text("Share"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        // If isDefault is false, remove from deck option
                        if (!widget.languageDeck.isDefault!)
                          const PopupMenuItem(
                            value: "remove",
                            height: 35,
                            child: SizedBox(
                              child: Row(
                                children: [
                                  Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  SizedBox(width: 10),
                                  Text(
                                    "Remove from deck",
                                  )
                                ],
                              ),
                            ),
                          ),

                        // Delete option
                        const PopupMenuItem(
                          value: "delete",
                          height: 35,
                          child: SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                Icon(Icons.delete_outlined, color: Colors.red),
                                SizedBox(width: 10),
                                Text("Delete",
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ), // Add space between the row and text
                Text(widget.languageCard.nativeText,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
