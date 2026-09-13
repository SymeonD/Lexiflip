import 'package:auto_size_text/auto_size_text.dart';
import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/country.dart';
import 'package:cards/models/country_card.dart';
import 'package:cards/models/country_deck.dart';
import 'package:cards/ui/card_dialog_view.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:flutter/material.dart';

class CountryCardView extends StatefulWidget {
  final CountryCard countryCard;
  final Country country;

  // OnDelete
  final VoidCallback onDelete;

  // Edit
  final CountryDeck countryDeck;

  const CountryCardView(
      {super.key,
      // required this.country,
      required this.countryCard,
      required this.onDelete,
      required this.countryDeck,
      required this.country});

  @override
  State createState() => _CountryCardViewState();
}

class _CountryCardViewState extends State<CountryCardView> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return CardDialogView(
            country: widget.country,
            countryCard: widget.countryCard,
            onCardAdded: widget.onDelete,
            countryDeck: widget.countryDeck,
            cardTag: widget.countryCard.countryCardId.toString(),
          );
        }));
      },
      child: Hero(
        tag: widget.countryCard.countryCardId.toString(),
        child: SizedBox(
          width: 200,
          height: 150, // Define the height of the container here
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            color: ThemeColors.backgroundColor,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      // Handle menu selection
                      if (value == "edit") {
                        // TODO: See if kept here ?
                        // Open the page to edit the card
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return CardDialogView(
                            country: widget.country,
                            countryCard: widget.countryCard,
                            onCardAdded: widget.onDelete,
                            countryDeck: widget.countryDeck,
                            cardTag:
                                widget.countryCard.countryCardId.toString(),
                          );
                        }));
                      } else if (value == "share") {
                        // Share the deck
                        // Show a bar at the bottom of the screen with a text 'Coming soon'
                        showCustomSnackBar( "Coming soon", 2);
                      } else if (value == "remove") {
                        // Remove the card from the deck
                        DatabaseHelper.instance.removeCardFromDeck(
                          widget.countryDeck.countryDeckId!,
                          widget.countryCard.countryCardId!,
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
                                        widget.countryCard.countryCardId!,
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
                    color: ThemeColors.backgroundColor,
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
                                    color: ThemeColors.primaryFontColor),
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
                                    color: ThemeColors.primaryFontColor),
                                SizedBox(width: 10),
                                Text("Share"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      // If isDefault is false, remove from deck option
                      if (!widget.countryDeck.isDefault!)
                        const PopupMenuItem(
                          value: "remove",
                          height: 35,
                          child: SizedBox(
                            child: Row(
                              children: [
                                Icon(Icons.remove_circle_outline,
                                    color: ThemeColors.deleteColor),
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
                              Icon(Icons.delete_outlined,
                                  color: ThemeColors.deleteColor),
                              SizedBox(width: 10),
                              Text("Delete",
                                  style: TextStyle(
                                      color: ThemeColors.deleteColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ), // Add space between the row and text
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, left: 16),
                    child: AutoSizeText(widget.countryCard.nativeText,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
