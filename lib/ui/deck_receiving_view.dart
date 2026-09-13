import 'dart:convert';

import 'package:cards/models/country.dart';
import 'package:cards/models/country_card.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/utils/get_device_name.dart';
import 'package:cards/utils/handle_share_permissions.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeckOffer {
  final String endpointId;
  final int deckId;
  final String deckName;
  final String sourceLanguageCode;
  final String targetLanguageCode;

  DeckOffer({
    required this.endpointId,
    required this.deckId,
    required this.deckName,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
}

class DeckReceivingView extends StatefulWidget {
  final Country country;
  final VoidCallback onDeckReceived;

  const DeckReceivingView({
    super.key,
    required this.country,
    required this.onDeckReceived,
  });

  @override
  State createState() => _DeckReceivingViewState();
}

class _DeckReceivingViewState extends State<DeckReceivingView> {
  List<DeckOffer> availableOffers = [];
  String? _myNativeLangCode;
  bool _downloading = false;
  String _username = 'Unknown User';
  
  static const Strategy strategy = Strategy.P2P_STAR;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    // Start discovering decks when the view is initialized
    _startDiscovering();
  }

  Future<void> _loadUserName() async {
    _username = await getDeviceName();
  }

  bool _isCompatible(DeckOffer offer) {
    final myTargetLang = widget.country.countryLanguageCode; // Default to 'en' if not set
    return offer.targetLanguageCode == myTargetLang &&
        offer.sourceLanguageCode == _myNativeLangCode;
  }

  Future<void> _startDiscovering() async {
    await handleShare(context);
    // Logic to start discovering decks
    // This is where you would implement the actual discovery logic
    // For now, we just simulate receiving a deck offer

    final prefs = await SharedPreferences.getInstance();
    _myNativeLangCode = prefs.getString('nativeLanguageCode') ?? 'en';

    await Nearby().startDiscovery(
      _username,
      strategy,
      onEndpointFound: (id, name, serviceId) async {
        Nearby().requestConnection(_username, id, onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(id, onPayLoadRecieved: (endid, payload) async {
            final data = utf8.decode(payload.bytes!);
            final jsonData = jsonDecode(data);

            if (jsonData['type'] == 'deck_offer') {
              final offer = DeckOffer(
                endpointId: id,
                deckId: jsonData['deckId'],
                deckName: jsonData['deckName'],
                sourceLanguageCode: jsonData['sourceLanguageCode'],
                targetLanguageCode: jsonData['targetLanguageCode'],
              );

              setState(() {
                availableOffers.removeWhere((existingOffer) => existingOffer.endpointId == id);
                availableOffers.add(offer);
              });
            } else if (jsonData['type'] == 'deck_data') {
              // Handle the received deck data
              final deckName = jsonData['deck']['deckName'];
              final cards = (jsonData['cards'] as List).map((card) => CountryCard(
                countryId: widget.country.countryId!,
                nativeText: card['nativeText'],
                nativeNote: card['nativeNote'],
                localText: card['localText'],
                localRomanization: card['localRomanization'],
              )).toList();

              // Save the received deck and cards to the database
              await DatabaseHelper.instance.insertDeckAndCards(
                widget.country.countryId!,
                deckName,
                cards,
              );

              setState(() {
                _downloading = false;
              });
              // Notify that a new deck has been received
              widget.onDeckReceived();
              showCustomSnackBar("Deck '$deckName' received successfully!", 2);
            }
          }, onPayloadTransferUpdate: (endid, update) {});
        }, onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            // Connection established
          } else {
            // Handle connection failure
          }
        }, onDisconnected: (id) {
          // Handle lost connection
          setState(() {
            availableOffers.removeWhere((offer) => offer.endpointId == id);
          });
        });
      },
      onEndpointLost: (id) {
        // Handle the lost endpoint
        setState(() {
          availableOffers.removeWhere((offer) => offer.endpointId == id);
        });
      },
    );
  }

  Future<void> requestDeck(DeckOffer offer) async {
    if(!_isCompatible(offer)) {
      showCustomSnackBar("At the moment, only decks with same source and target languages can be requested.", 2);
      return;
    }
    setState(() {
      _downloading = true;
    });

    try {
      final payload = {
        'type': 'deck_request',
        'deckId': offer.deckId,
      };

      await Nearby().sendBytesPayload(offer.endpointId, utf8.encode(jsonEncode(payload)));
    } catch (e) {
      showCustomSnackBar("Failed to request deck: $e", 2);
      setState(() {
        _downloading = false;
      });
    }
  }

  @override
  void dispose() {
    Nearby().stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Available Decks'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 300,
        child: _downloading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                shrinkWrap: true,
                itemCount: availableOffers.length,
                itemBuilder: (context, index) {
                  final offer = availableOffers[index];
                  return ListTile(
                    title: Text(offer.deckName),
                    subtitle: Text('Source: ${offer.sourceLanguageCode}, Target: ${offer.targetLanguageCode}'),
                    trailing: ElevatedButton(
                      onPressed: () => requestDeck(offer),
                      child: const Text('Request'),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}