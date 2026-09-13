import 'dart:convert';

import 'package:cards/models/country.dart';
import 'package:cards/models/country_deck.dart';
import 'package:cards/models/database_helper.dart';
import 'package:cards/utils/get_device_name.dart';
import 'package:cards/utils/handle_share_permissions.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeckSharingView extends StatefulWidget {
  final Country country;
  final CountryDeck countryDeck;

  const DeckSharingView({
    super.key,
    required this.country,
    required this.countryDeck,
  });

  @override
  State createState() => _DeckSharingViewState();
}

class _DeckSharingViewState extends State<DeckSharingView> {
  List<String> connectedUsers = []; // Placeholder for connected user names
  // Set device name for Nearby Connections
  String _userName = 'Unknown User'; // You can set this to a unique identifier for the device
  Strategy strategy = Strategy.P2P_STAR; // Choose the appropriate strategy

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _startSharing(); // Start sharing after permissions are handled
  }

  Future<void> _loadUserName() async {
    _userName = await getDeviceName();
  }

  Future<void> _startSharing() async {
    await handleShare(context);
    // Logic to start sharing the deck
    // This is where you would implement the actual sharing logic
    // For now, we just simulate sharing by adding a user to the list
    final Map<String, String> _pendingConnections = {}; // Map to hold pending connections
    final prefs = await SharedPreferences.getInstance();
    final nativeLangCode = prefs.getString('nativeLanguageCode') ?? 'en'; // Default to 'en' if not set
    final targetLangCode = widget.country.countryLanguageCode; // Default to 'en' if not set

    await Nearby().startAdvertising(_userName, strategy, 
    onConnectionInitiated: (id, info) {
      _pendingConnections[id] = info.endpointName;
      Nearby().acceptConnection(id, 
        onPayLoadRecieved: (endid, payload) async {
        // Should not receive anything here
        final data = utf8.decode(payload.bytes!);
        final jsonData = jsonDecode(data);

        // Handle the received data, specifying what we get to send
        if(jsonData['type'] == 'deck_request' && jsonData['deckId'] == widget.countryDeck.countryDeckId) {
          final cards = await DatabaseHelper.instance.getCards(widget.countryDeck.countryDeckId!, widget.country.countryId!);
          final deckPayload = {
            'type': 'deck_data',
            'deck': {
              'deckName': widget.countryDeck.countryDeckName,
            },
            'cards': cards.map((card) => {
              "nativeText": card!.nativeText,
              "nativeNote": card.nativeNote,
              "localText": card.localText,
              'localRomanization': card.localRomanization,
            }).toList(),
          };
          
          final bytes = utf8.encode(jsonEncode(deckPayload));
          Nearby().sendBytesPayload(endid, bytes).then((_) {
            showCustomSnackBar("Deck sent to ${_pendingConnections[endid] ?? "Unknown User"}", 2);
          }).catchError((error) {
            showCustomSnackBar("Failed to send deck: $error", 2);
          });
        }
      }, onPayloadTransferUpdate: (endid, update) {});
    }, onConnectionResult: (id, status) async {
      if(status == Status.CONNECTED) {
        // Handle successful connection
        setState(() {
          connectedUsers.add(_pendingConnections[id] ?? "Unknown User"); // Add the connected user's ID to the list
        });

        final offerPayload = {
          "type": "deck_offer",
          "deckId": widget.countryDeck.countryDeckId,
          "deckName": widget.countryDeck.countryDeckName,
          "sourceLanguageCode": nativeLangCode,
          "targetLanguageCode": targetLangCode,
        };

        await Nearby().sendBytesPayload(id, utf8.encode(jsonEncode(offerPayload)));

      } else if (status == Status.REJECTED) {
        // Handle rejected connection
        showCustomSnackBar("Connection rejected by ${_pendingConnections[id] ?? "Unknown User"}", 2);
      } else if (status == Status.ERROR) {
        // Handle error in connection
        showCustomSnackBar("Error connecting to ${_pendingConnections[id] ?? "Unknown User"}", 2);
      }
      
      _pendingConnections.remove(id); // Remove from pending connections
    }, onDisconnected: (id) {
      // Handle disconnection
      setState(() {
        connectedUsers.remove(_pendingConnections[id] ?? "Unknown User");
      });
    });
  }

  @override
  void dispose() {
    Nearby().stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sharing Deck'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sharing the deck "${widget.countryDeck.countryDeckName}" with ${connectedUsers.length} users: '),
          const SizedBox(height: 20),
          // List of connected users (placeholder)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7, // largeur concrète, pas infinie
            height: 200, // hauteur bornée aussi, nécessaire pour un ListView
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: connectedUsers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('User ${index + 1}'),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}