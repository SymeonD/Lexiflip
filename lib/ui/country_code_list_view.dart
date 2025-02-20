import 'package:canopas_country_picker/canopas_country_picker.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:cards/utils/manage_language_model.dart';
import 'package:flutter/material.dart';

class CountryCodeListView extends StatelessWidget {
  final List<CountryCode> codes;
  final ScrollController? controller;

  const CountryCodeListView(
      {super.key, required this.codes, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: codes.length,
      itemBuilder: (context, index) {
        final code = codes[index];
        return ListTile(
          title: Text(code.name),
          leading: Text(code.flag, style: const TextStyle(fontSize: 24)),
          onTap: () {
            Navigator.pop(context, code);
          },
        );
      },
    );
  }
}
