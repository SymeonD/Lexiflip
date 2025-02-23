import 'package:cards/models/database_helper.dart';
import 'package:cards/pages/home_page.dart';
import 'package:cards/pages/starting_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Check if the setting "nativeCountryCode" exists
  String? nativeCountryCode = prefs.getString('nativeCountryCode');
  // Initialize the database by ensuring it's opened
  await DatabaseHelper.instance.database;
  runApp(MyApp(nativeCountryCode: nativeCountryCode));
}

class MyApp extends StatelessWidget {
  final String? nativeCountryCode;

  const MyApp({super.key, this.nativeCountryCode});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cards',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
            seedColor: ThemeColors.primaryColor,
            surface: ThemeColors.backgroundColor,
            // ignore: deprecated_member_use
            background: ThemeColors.backgroundColor),
        useMaterial3: true,
      ),
      home: nativeCountryCode == null ? const StartingPage() : const HomePage(),
    );
  }
}

class ThemeColors {
  static const Color primaryColor = Color(0xFF1EA6C6);
  static const Color secondaryColor = Color(0xFFF7CF52);

  static const Color backgroundColor = Color(0xFFFFFFFF);

  static const Color primaryFontColor = Color(0xDD000000);
  static const Color secondaryFontColor = Colors.black54;

  static const Color primaryWhiteFontColor = Color(0xFFFFFFFF);
  static const Color secondaryWhiteFontColor = Color(0x8AFFFFFF);

  static const Color disabledColor = Color(0x1A000000);

  static const Color deleteColor = Color(0xFFFF0000);
  static const Color validColor = Color(0xFF00FF00);
}
