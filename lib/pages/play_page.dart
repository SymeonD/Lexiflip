// In: deck
// Get: cards
// Out: deck

import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:confetti/confetti.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayPage extends StatefulWidget {
  const PlayPage(
      {super.key,
      required this.languageDeck,
      required this.language,
      this.carMode});
  final LanguageDeck languageDeck;
  final Language language;
  final bool? carMode;

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

  FlutterTts cardTts = FlutterTts();
  String nativeTtsCode = 'en-Us';
  String localTtsCode = 'en-Us';

  // Confetti controller
  late ConfettiController _controllerCenter;

  CardSwiperDirection swipeDirection = CardSwiperDirection.none;

  Timer? _playCarModeTimer;

  Future<bool> _loadCards() async {
    try {
      final db = DatabaseHelper.instance;
      var cardList = await db.getCards(widget.languageDeck.languageDeckId!,
          widget.language.languageId!, widget.languageDeck.isDefault!);
      // Add an empty card to the list
      // cardList.add(LanguageCard(languageId: 1, nativeText: "", localText: ""));
      setState(() {
        cards.addAll(cardList);
        cards.shuffle();
        cardsLength = cards.length;
        cardFlipStates = List<bool>.filled(cardsLength, true);
      });
      return true;
    } catch (e) {
      Logger().e("Error loading cards: $e");
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 1));
    _loadCards().then((value) => {
          initTts().then((value) =>
              {widget.carMode ?? value && false ? playCarMode() : null})
        });
  }

  Future<bool> initTts() async {
    cardTts.setSpeechRate(0.4);

    Completer<void> completer = Completer();

    // Set the tts
    SharedPreferences.getInstance().then((prefs) => {
          cardTts.getLanguages.then((languages) => {
                languages.forEach((lang) => {
                      lang.toString().split("-")[0] ==
                              getLanguageCode(widget.language.languageCode)
                          ? {
                              localTtsCode = lang,
                              Logger().i("Found : $lang for local")
                            }
                          : "",
                      lang == "${getLanguageCode(prefs.getString("nativeLanguageCode")!)}-${prefs.getString("nativeLanguageCode")!.toUpperCase()}"
                          ? {
                              nativeTtsCode = lang,
                              Logger().i("Found : $lang for native")
                            }
                          : "",
                      // If both values are found, complete the future
                      if ((localTtsCode != 'en-US' &&
                              nativeTtsCode != 'en-US' &&
                              !completer.isCompleted) ||
                          ((languages.indexOf(lang) == languages.length - 1) &&
                              !completer.isCompleted))
                        {completer.complete()}
                    })
              })
        });

    await completer.future;

    return true;
  }

  void _toggleCardFlip(int index) {
    setState(() {
      cardFlipStates[index] = !cardFlipStates[index]; // Toggle card flip
    });
  }

  void _restartGame() {
    setState(() {
      _loadCards()
          .then((value) => {widget.carMode ?? true ? playCarMode() : null});
    });
  }

  // Find a way to cancel
  void playCarMode() {
    void playNextCard() {
      if (!mounted) return; // Do nothing if widget is disposed

      if (cards.isNotEmpty) {
        Logger().i("Playing card ${cards[0]!.nativeText}");

        cardTts.setLanguage(nativeTtsCode).then((_) {
          if (!mounted) return;
          cardTts.speak(cards[0]!.nativeText).then((_) {
            if (!mounted) return;
            Future.delayed(const Duration(seconds: 2), () {
              if (!mounted) return;
              _toggleCardFlip(0);
              cardTts.setLanguage(localTtsCode).then((_) {
                if (!mounted) return;
                cardTts.speak(cards[0]!.localText).then((_) {
                  if (!mounted) return;
                  Future.delayed(const Duration(seconds: 2), () {
                    if (!mounted) return;
                    _toggleCardFlip(0);
                    swiperController.swipe(CardSwiperDirection.right);
                    _playCarModeTimer =
                        Timer(const Duration(seconds: 1), playNextCard);
                  });
                });
              });
            });
          });
        });
      } else {
        _playCarModeTimer?.cancel();
      }
    }

    playNextCard();
  }

  @override
  void dispose() {
    swiperController.dispose();
    _controllerCenter.dispose();
    cardTts.stop();
    _playCarModeTimer?.cancel(); // Cancel any active timer
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
          : Stack(
              children: [
                // Glowing half circle at the right side
                Positioned(
                  top: 50,
                  right: swipeDirection == CardSwiperDirection.right ? 0 : null,
                  left: swipeDirection == CardSwiperDirection.left ? 0 : null,
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: MediaQuery.of(context).size.width,
                        height: 475,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          gradient: RadialGradient(
                            center: Alignment.centerLeft, // Static center
                            radius: swipeDirection == CardSwiperDirection.left
                                ? 0.4
                                : 0, // Animated radius
                            colors: [
                              Colors.red,
                              Theme.of(context)
                                  .colorScheme
                                  .surface, // Ensure smooth fade-out
                            ],
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: MediaQuery.of(context).size.width,
                        height: 475,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          gradient: RadialGradient(
                            center: Alignment.centerRight, // Static center
                            radius: swipeDirection == CardSwiperDirection.right
                                ? 0.4
                                : 0, // Animated radius
                            colors: [
                              Colors.green,
                              Theme.of(context)
                                  .colorScheme
                                  .surface, // Ensure smooth fade-out
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
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
                    onSwipeDirectionChange:
                        (horizontalDirection, verticalDirection) => {
                      // Update swipe direction here to handle the gradient color change dynamically
                      if (horizontalDirection != swipeDirection)
                        {
                          setState(() {
                            swipeDirection = horizontalDirection;
                          })
                        }
                    },

                    // After the swipe is finished
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
                          cardsLength =
                              cards.length; // Update cardsLength properly
                        });
                        return previousIndex == cardsLength ? true : false;
                        // }
                      } else {
                        return true;
                      }
                    },

                    // While building
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      int distanceToIndex = index - cardsLength + 1;
                      index =
                          distanceToIndex > 0 ? index - distanceToIndex : index;
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
                const SizedBox(
                  height: double.infinity,
                )
              ],
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
            (card!.nativeNote != null && card.nativeNote!.trim().isNotEmpty)
                ? Align(
                    alignment: Alignment.topRight,
                    child: Padding(
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
                    ))
                : const Spacer(),
            Center(
              child: SizedBox(
                width: 300,
                child: AutoSizeText(card.nativeText,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    maxFontSize: hint ? 20 : 32,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            hint
                ? Center(
                    child: SizedBox(
                      width: 300,
                      height: 50,
                      child: AutoSizeText(card.nativeNote ?? "",
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                    ),
                  )
                : const Spacer(),
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
                      Logger().i("Language: $localTtsCode");
                      cardTts.setLanguage(localTtsCode);
                      cardTts.speak(card!.localText);
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
              child: SizedBox(
                width: 300,
                child: AutoSizeText(card!.localText,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize:
                            card.localRomanization?.trim() != "" ? 20 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            card.localRomanization?.trim() != ""
                ? Center(
                    child: SizedBox(
                      width: 300,
                      height: 50,
                      child: AutoSizeText(card.localRomanization!,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white60)),
                    ),
                  )
                : const Spacer(),
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
