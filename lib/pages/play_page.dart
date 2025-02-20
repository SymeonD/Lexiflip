// In: deck
// Get: cards
// Out: deck

import 'dart:math';

import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:confetti/confetti.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

class PlayPage extends StatefulWidget {
  const PlayPage(
      {super.key, required this.languageDeck, required this.language});
  final LanguageDeck languageDeck;
  final Language language;

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  final List<LanguageCard?> cards = [];
  int cardsLength = 0;

  CardSwiperController swiperController = CardSwiperController();

  List<bool> cardFlipStates = [];
  bool currentFlipState = true;

  bool hint = false;

  FlutterTts flutterTts = FlutterTts();

  int deleteOffset = 0;

  // Confetti controller
  late ConfettiController _controllerCenter;

  void _loadCards() async {
    try {
      final db = DatabaseHelper.instance;
      var cardList = await db.getCards(widget.languageDeck.languageDeckId!,
          widget.language.languageId!, widget.languageDeck.isDefault!);
      // Add an empty card to the list
      // cardList.add(LanguageCard(languageId: 1, nativeText: "", localText: ""));
      setState(() {
        cards.addAll(cardList);
        cardsLength = cards.length;
        cardFlipStates = List<bool>.filled(cardsLength, true);
      });
    } catch (e) {
      Logger().e("Error loading cards: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 1));
    _loadCards(); // All front by default
    initTts();
  }

  void initTts() {
    flutterTts.setSpeechRate(0.4);

    // Loop through the flutterTts languages
    flutterTts.getLanguages.then((languages) => {
          languages.forEach((lang) =>
              lang.contains(widget.language.languageCode)
                  ? {flutterTts.setLanguage(lang)}
                  : "")
        });
  }

  void _toggleCardFlip(int index) {
    setState(() {
      cardFlipStates[index] = !cardFlipStates[index]; // Toggle card flip
    });
  }

  void _restartGame() {
    setState(() {
      _loadCards();
      cards.shuffle();
      deleteOffset = 0;
    });
  }

  @override
  void dispose() {
    swiperController.dispose();
    _controllerCenter.dispose();
    flutterTts.stop();
    super.dispose();
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
                  widget.languageDeck.languageDeckName,
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
      body: cards.isEmpty
          ? Center(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height / 4),
                  const Text(
                    "You finished the deck !",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ConfettiWidget(
                    confettiController: _controllerCenter,
                    blastDirectionality: BlastDirectionality
                        .explosive, // don't specify a direction, blast randomly
                    shouldLoop:
                        false, // start again as soon as the animation is finished
                    emissionFrequency: 0.005,
                    numberOfParticles: 100,
                    // colors: const [
                    //   Colors.green,
                    //   Colors.blue,
                    //   Colors.pink,
                    //   Colors.orange,
                    //   Colors.purple
                    // ], // manually specify the colors to be used
                    colors: const [Color(0xff1EA6C6), Color(0xffF4581B)],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Restart Button
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              fixedSize: const Size(75, 75),
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                              )),
                          onPressed: () {
                            _restartGame();
                          },
                          child: const Icon(
                            Icons.restart_alt_rounded,
                            size: 30,
                          )),
                      const SizedBox(width: 16),
                      // Leave Button
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              fixedSize: const Size(75, 75),
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                              )),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            Icons.logout_outlined,
                            size: 30,
                          )),
                    ],
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 400,
              child: CardSwiper(
                backCardOffset: const Offset(0, 30),
                cardsCount: cardsLength,
                numberOfCardsDisplayed: cardsLength > 1 ? 2 : 1,
                // isDisabled: cardsLength <= 2,
                controller: swiperController,
                // isLoop: false,
                allowedSwipeDirection:
                    const AllowedSwipeDirection.symmetric(horizontal: true),
                onSwipe: (previousIndex, currentIndex, direction) {
                  setState(() {
                    // Reset current flip state
                    currentFlipState = true;
                    // Reset hint state
                    hint = false;
                    // Reset face
                    cardFlipStates[previousIndex] = true;
                  });
                  if (direction == CardSwiperDirection.right) {
                    setState(() {
                      if (cards.length > 1) {
                        cards.removeAt(previousIndex);
                      } else {
                        cards
                            .clear(); // Ensure the last card is removed correctly
                        _controllerCenter.play();
                      }
                      cardsLength = cards.length; // Update cardsLength properly
                    });
                    return previousIndex == cardsLength ? true : false;
                    // }
                  } else {
                    return true;
                  }
                },
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                  int distanceToIndex = index - cardsLength + 1;
                  index = distanceToIndex > 0 ? index - distanceToIndex : index;
                  Logger().i(
                      "Current index: $index, Cards remaining: $cardsLength");
                  final card = cards[index];
                  return Align(
                    alignment: const Alignment(0, 1),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      onTap: () => {
                        _toggleCardFlip(index),
                        currentFlipState = !currentFlipState
                      },
                      child: AnimatedSwitcher(
                        key: ValueKey<int>(index),
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: __transitionBuilder,
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeOutBack.flipped,
                        child: KeyedSubtree(
                          key: ValueKey<bool>(cardFlipStates[index]),
                          child: cardFlipStates[index]
                              ? _buildFront(card)
                              : _buildBack(card),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildFront(LanguageCard? card) {
    return SizedBox(
      width: double.infinity,
      height: 200, // Define the height of the container here
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add space between the row and text
            Align(
                alignment: Alignment.topRight,
                child: (card!.nativeNote != null &&
                        card.nativeNote!.trim().isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: IconButton(
                            onPressed: () {
                              setState(() => hint = !hint);
                            },
                            icon: Icon(
                              hint
                                  ? Icons.flashlight_off_outlined
                                  : Icons.flashlight_on_outlined,
                              color: Colors.green.shade400,
                              size: 35,
                            )),
                      )
                    : const SizedBox(
                        height: 61,
                      )),
            Center(
              child: Text(card.nativeText,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            hint
                ? Center(
                    child: Text(card.nativeNote ?? "",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54)),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(LanguageCard? card) {
    return SizedBox(
      width: double.infinity,
      height: 200, // Define the height of the container here
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: const Color.fromARGB(255, 101, 80, 163),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                  onPressed: () {
                    try {
                      flutterTts.setLanguage('en-US');
                      flutterTts.speak(card!.localText);
                    } catch (e) {
                      Logger().e("Error speaking: $e");
                    }
                  },
                  icon: Icon(
                    Icons.volume_up_outlined,
                    color: Colors.yellow.shade400,
                    size: 40,
                  )),
            ),
            // Add space between the row and text
            Center(
              child: Text(card!.localText,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            const SizedBox(height: 10),
            card.localRomanization != null
                ? Center(
                    child: Text(card.localRomanization!,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white60)),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget __transitionBuilder(Widget widget, Animation<double> animation) {
    final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotateAnim,
      child: widget,
      builder: (context, widget) {
        final isUnder = (ValueKey(currentFlipState) == widget!.key);

        var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
        tilt *= isUnder ? -1.0 : 1.0;
        final value =
            isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
        return Transform(
          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
          alignment: Alignment.center,
          child: widget,
        );
      },
    );
  }
}
