import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/pages/language_deck_cards_page.dart';
import 'package:cards/pages/play_page.dart';
import 'package:cards/ui/deck_dialog_view.dart';
import 'package:cards/utils/handle_share_permissions.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nearby_connections/nearby_connections.dart';

class LanguageDeckView extends StatefulWidget {
  final Language language;
  final LanguageDeck languageDeck;
  final VoidCallback onDelete;

  const LanguageDeckView(
      {super.key,
      required this.language,
      required this.languageDeck,
      required this.onDelete});

  @override
  State createState() => _LanguageDeckViewState();
}

class _LanguageDeckViewState extends State<LanguageDeckView> {
  int _deckCardCount = 0;
  double scaleA = 1;

  // Load the number of cards in the deck
  void _loadDeckCardCount() async {
    // Get the number of cards in the deck
    _deckCardCount = await DatabaseHelper.instance.getDeckCardCount(
        widget.languageDeck.languageDeckId!,
        widget.languageDeck.isDefault!,
        widget.language.languageId!);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadDeckCardCount();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LanguageCardPage(
                    language: widget.language,
                    languageDeck: widget.languageDeck,
                    onCardEdited: _loadDeckCardCount)));
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      // Then start the connection
                      const String userName = "LexiFlip";
                      const Strategy strategy = Strategy.P2P_STAR;

                      // Handle menu selection
                      if (value == "edit" && !widget.languageDeck.isDefault!) {
                        // Edit the deck
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return DeckDialogView(
                                language: widget.language,
                                languageDeck: widget.languageDeck,
                                onDelete: _loadDeckCardCount,
                              );
                            });
                      } else if (value == "share") {
                        // Share the deck
                        // check for rights
                        await handleShare(context);

                        await Nearby().startAdvertising(userName, strategy,
                            onConnectionInitiated: (id, info) {
                          Nearby().acceptConnection(id,
                              onPayLoadRecieved: (endpointId, payload) {
                            // Handle received payload here
                            // For example, you can decode the payload and show it in a dialog
                            showCustomSnackBar(context, "payload received", 2);
                          }, onPayloadTransferUpdate: (endpointId, update) {
                            // Handle progress or completion here
                            Logger()
                                .i("Payload transfer update: ${update.status}");
                          });
                          showCustomSnackBar(
                              context, "connection initiated", 2);
                        }, onConnectionResult: (id, status) async {
                          if (status == Status.CONNECTED) {
                            showCustomSnackBar(
                                context, "Connection successful", 2);

                            // Create the payload
                            final deckload = {
                              "deckName": widget.languageDeck.languageDeckName,
                              "languageId": widget.language.languageId,
                            };
                            final payload = {
                              "deck": deckload,
                              "cards": [],
                            };
                            // Get the cards in the deck
                            final cards = await DatabaseHelper.instance
                                .getCards(widget.languageDeck.languageDeckId!,
                                    widget.languageDeck.languageId);
                            // Add the cards to the payload
                            payload["cards"] = cards
                                .map((card) => {
                                      "nativeText": card!.nativeText,
                                      "nativeNote": card.nativeNote,
                                      "localText": card.localText,
                                      "localRomanization":
                                          card.localRomanization,
                                    })
                                .toList();
                            final bytes = utf8.encode(jsonEncode(payload));
                            // Send the payload
                            Nearby().sendBytesPayload(id, bytes).then((_) {
                              showCustomSnackBar(context, "Payload sent", 2);
                            }).catchError((error) {
                              showCustomSnackBar(
                                  context, "Failed to send payload: $error", 2);
                            });
                          } else {
                            showCustomSnackBar(context, "Connection failed", 2);
                          }
                        }, onDisconnected: (id) {
                          showCustomSnackBar(context, "Disconnected", 2);
                        });
                      } else if (value == "delete") {
                        // Delete the deck, show a confirmation dialog if more than 0 cards
                        if (_deckCardCount > 0) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Delete deck",
                                    style: TextStyle(
                                        color: ThemeColors.primaryFontColor,
                                        fontWeight: FontWeight.bold)),
                                content: const Text(
                                    "This deck contains cards, are you sure you want to delete it ?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Delete the deck
                                      DatabaseHelper.instance.deleteDeck(
                                          widget.languageDeck.languageDeckId!);
                                      widget.onDelete();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Delete",
                                        style: TextStyle(
                                            color: ThemeColors.deleteColor)),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          // Delete the deck
                          DatabaseHelper.instance
                              .deleteDeck(widget.languageDeck.languageDeckId!);
                          widget.onDelete();
                        }
                        setState(() {
                          // Remove the deck from the list
                        });
                      }
                    },
                    offset: const Offset(0, 40),
                    color: ThemeColors.backgroundColor,
                    icon: const Icon(Icons.more_horiz),
                    itemBuilder: (BuildContext context) => [
                      // Edit option
                      PopupMenuItem(
                        enabled: !widget.languageDeck.isDefault!,
                        value: "edit",
                        height: 35,
                        padding: const EdgeInsets.only(left: 10),
                        child: const IntrinsicWidth(
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
                      PopupMenuItem(
                        enabled: widget.languageDeck.languageDeckCards != null && widget.languageDeck.languageDeckCards!.isNotEmpty,
                        value: "share",
                        height: 35,
                        child: const IntrinsicWidth(
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
                ],
              ),
              SizedBox(
                height:
                    150, // Controls the height of the row with the two containers
                width: 175,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ClipPath(
                      clipper: MyCustomClipperLeft(), // Clipping the InkWell
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            _deckCardCount > 0
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => PlayPage(
                                              language: widget.language,
                                              languageDeck: widget.languageDeck,
                                              carMode: true,
                                            )))
                                : showCustomSnackBar(
                                    context,
                                    "This deck is empty, add cards to it to play",
                                    2);
                          },
                          child:
                              // Left side, car mode, blue
                              CustomPaint(
                            painter: MyPainterLeft(),
                            child: const Stack(children: [
                              SizedBox(
                                height: 150,
                                width: 75,
                              ),
                              Positioned(
                                top: 53,
                                left: 13,
                                child: Icon(Icons.auto_stories_outlined,
                                    color: ThemeColors.backgroundColor,
                                    size: 45),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    ClipPath(
                      clipper: MyCustomClipperRight(), // Clipping the InkWell
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            _deckCardCount > 0
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => PlayPage(
                                              language: widget.language,
                                              languageDeck: widget.languageDeck,
                                            )))
                                : showCustomSnackBar(
                                    context,
                                    "This deck is empty, add cards to it to play",
                                    2);
                          },
                          child: CustomPaint(
                            size: const Size(75, 150), // Adjust size as needed
                            painter: MyPainterRight(),
                            child: const Stack(children: [
                              SizedBox(
                                height: 150,
                                width: 75,
                              ),
                              Positioned(
                                top: 47,
                                right: 14,
                                child: Icon(Icons.play_arrow_outlined,
                                    color: ThemeColors.backgroundColor,
                                    size: 55),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // Add space between the row and text
              SizedBox(
                width: 150,
                child: Center(
                  child: AutoSizeText(widget.languageDeck.languageDeckName,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              Text("$_deckCardCount card${_deckCardCount > 1 ? "s" : ""}"),
            ],
          ),
        ),
      ),
    );
  }
}

class MyPainterLeft extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number 1

    path = getCustomPathLeft(size);
    paint.color = ThemeColors.primaryColor;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class MyCustomClipperLeft extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return getCustomPathLeft(size); // Use the same shape for clipping
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

Path getCustomPathLeft(Size size) {
  Path path = Path();
  path.lineTo(size.width, size.height / 2);
  path.cubicTo(size.width, size.height * 0.76, size.width, size.height * 0.73,
      size.width, size.height * 0.96);
  path.cubicTo(size.width, size.height * 0.98, size.width * 0.96, size.height,
      size.width * 0.91, size.height);
  path.cubicTo(size.width * 0.4, size.height * 0.98, 0, size.height * 0.76, 0,
      size.height / 2);
  path.cubicTo(0, size.height * 0.24, size.width * 0.4, size.height * 0.03,
      size.width * 0.91, 0);
  path.cubicTo(size.width * 0.96, 0, size.width, size.height * 0.02, size.width,
      size.height * 0.05);
  path.cubicTo(size.width, size.height * 0.39, size.width, size.height * 0.24,
      size.width, size.height / 2);
  path.cubicTo(size.width, size.height / 2, size.width, size.height / 2,
      size.width, size.height / 2);
  path.close();
  return path;
}

class MyPainterRight extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number 1
    path = getCustomPathRight(size);
    paint.color = ThemeColors.secondaryColor;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class MyCustomClipperRight extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return getCustomPathRight(size); // Use the same shape for clipping
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

Path getCustomPathRight(Size size) {
  Path path = Path();
  path.lineTo(0, size.height / 2);
  path.cubicTo(
      0, size.height * 0.24, 0, size.height * 0.28, 0, size.height * 0.05);
  path.cubicTo(
      0, size.height * 0.02, size.width * 0.04, 0, size.width * 0.09, 0);
  path.cubicTo(size.width * 0.6, size.height * 0.03, size.width,
      size.height * 0.24, size.width, size.height / 2);
  path.cubicTo(size.width, size.height * 0.76, size.width * 0.6,
      size.height * 0.98, size.width * 0.09, size.height);
  path.cubicTo(size.width * 0.04, size.height, 0, size.height * 0.98, 0,
      size.height * 0.96);
  path.cubicTo(
      0, size.height * 0.62, 0, size.height * 0.77, 0, size.height / 2);
  path.cubicTo(0, size.height / 2, 0, size.height / 2, 0, size.height / 2);
  path.close();
  return path;
}
