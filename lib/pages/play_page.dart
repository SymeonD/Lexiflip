import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cards/main.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/models/language.dart';
import 'package:cards/models/language_card.dart';
import 'package:cards/models/language_deck.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:confetti/confetti.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
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

  // List<bool> cardFlipStates = [];
  List<FlipCardController> flipCardControllers = [];
  bool currentFlipState = true; // True is front facing

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
      setState(() {
        cards.addAll(cardList);
        cards.shuffle();
        cardsLength = cards.length;
        // cardFlipStates = List<bool>.filled(cardsLength, true);
        flipCardControllers =
            List<FlipCardController>.filled(cardsLength, FlipCardController());
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
    cardTts.awaitSpeakCompletion(true);
    Completer<void> completer = Completer();

    // Set the tts
    SharedPreferences.getInstance().then((prefs) => {
          cardTts.getLanguages.then((languages) => {
                languages.forEach((lang) => {
                      lang.toString().split("-")[0] ==
                              getLanguageCode(
                                  widget.language.languageCode, context)
                          ? {
                              localTtsCode = lang,
                              Logger().i("Found : $lang for local")
                            }
                          : "",
                      lang == "${getLanguageCode(prefs.getString("nativeLanguageCode")!, context)}-${prefs.getString("nativeLanguageCode")!.toUpperCase()}"
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

  void _restartGame() {
    setState(() {
      _loadCards()
          .then((value) => {widget.carMode ?? true ? playCarMode() : null});
    });
  }

  int _autoPlaySessionId = 0; // Unique ID for autoplay session
  bool _isAutoPlaying = false;

  void playCarMode() {
    stopCarMode(); // Fully stop previous session
    _isAutoPlaying = true;
    _autoPlaySessionId++; // Generate a new session ID
    int currentSessionId = _autoPlaySessionId;

    void playNextCard() {
      if (!mounted || !_isAutoPlaying || currentSessionId != _autoPlaySessionId)
        return;

      if (cards.isNotEmpty) {
        cardTts.stop();

        cardTts.setLanguage(nativeTtsCode).then((_) {
          if (!mounted ||
              !_isAutoPlaying ||
              currentSessionId != _autoPlaySessionId) return;
          cardTts.speak(cards[0]!.nativeText).then((_) {
            if (!mounted ||
                !_isAutoPlaying ||
                currentSessionId != _autoPlaySessionId) return;
            Future.delayed(const Duration(seconds: 3), () {
              if (!mounted ||
                  !_isAutoPlaying ||
                  currentSessionId != _autoPlaySessionId) return;
              flipCardControllers[0].flipcard();

              cardTts.setLanguage(localTtsCode).then((_) {
                if (!mounted ||
                    !_isAutoPlaying ||
                    currentSessionId != _autoPlaySessionId) return;
                cardTts.speak(cards[0]!.localText).then((_) {
                  if (!mounted ||
                      !_isAutoPlaying ||
                      currentSessionId != _autoPlaySessionId) return;
                  Future.delayed(const Duration(seconds: 3), () {
                    if (!mounted ||
                        !_isAutoPlaying ||
                        currentSessionId != _autoPlaySessionId) return;
                    flipCardControllers[0].flipcard();
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
        stopCarMode();
      }
    }

    playNextCard();
  }

  void stopCarMode() {
    _isAutoPlaying = false;
    _autoPlaySessionId++; // Invalidate all previous sessions
    _playCarModeTimer?.cancel();
    cardTts.stop();
  }

  void onCardSwipedAuto() {
    stopCarMode();
    playCarMode();
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
                    colors: const [
                      ThemeColors.primaryColor,
                      ThemeColors.secondaryColor
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Restart Button
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeColors.backgroundColor,
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
                              backgroundColor: ThemeColors.backgroundColor,
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
                            colors: const [
                              ThemeColors.deleteColor,
                              ThemeColors
                                  .backgroundColor, // Ensure smooth fade-out
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
                            colors: const [
                              ThemeColors.validColor,
                              ThemeColors
                                  .backgroundColor, // Ensure smooth fade-out
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
                        widget.carMode != null && widget.carMode!
                            ? const AllowedSwipeDirection.only(right: true)
                            : const AllowedSwipeDirection.symmetric(
                                horizontal: true),
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
                        // Reset hint state
                        hint = false;
                        // Reset face
                        flipCardControllers[previousIndex].state != null &&
                                flipCardControllers[previousIndex]
                                    .state!
                                    .isFront
                            ? null
                            : flipCardControllers[previousIndex]
                                .state!
                                .isFront = true;
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
                        widget.carMode ?? true ? onCardSwipedAuto() : null;
                        return previousIndex == cardsLength ? true : false;
                        // }
                      } else {
                        widget.carMode ?? true ? onCardSwipedAuto() : null;
                        return true;
                      }
                    },

                    // While building
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      int distanceToIndex = index - cardsLength + 1;
                      int finalIndex =
                          distanceToIndex > 0 ? index - distanceToIndex : index;
                      final card = cards[finalIndex];

                      return Align(
                        alignment: const Alignment(0, 1),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          // onTap: () => {
                          //   // _toggleCardFlip(index),
                          //   flipCardControllers[index].flipcard(),
                          //   currentFlipState = !currentFlipState
                          // },
                          child: FlipCard(
                            animationDuration:
                                const Duration(milliseconds: 300),
                            rotateSide: RotateSide.right,
                            onTapFlipping: true,
                            frontWidget: _buildFront(card),
                            backWidget: _buildBack(card),
                            controller: flipCardControllers[index],
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
        color: ThemeColors.backgroundColor,
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
                            // TODO: Add to color theme
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
                              color: ThemeColors.secondaryFontColor)),
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
        color: ThemeColors.primaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                  onPressed: () {
                    try {
                      cardTts.setLanguage(localTtsCode);
                      cardTts.speak(card!.localText);
                    } catch (e) {
                      Logger().e("Error speaking: $e");
                    }
                  },
                  icon: Icon(
                    Icons.volume_up_outlined,
                    // TODO: Add to color theme
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
                        color: ThemeColors.primaryWhiteFontColor)),
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
                              color: ThemeColors.secondaryWhiteFontColor)),
                    ),
                  )
                : const Spacer(),
          ],
        ),
      ),
    );
  }
}
