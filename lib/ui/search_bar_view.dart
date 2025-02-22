import 'package:flutter/material.dart';

class SearchBarView extends StatefulWidget {
  final TextEditingController searchController;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final int? inputMaxLength;
  const SearchBarView(
      {super.key,
      required this.searchController,
      required this.hintText,
      this.onChanged,
      this.icon,
      this.inputMaxLength});

  @override
  State<SearchBarView> createState() => _SearchBarViewState();
}

class _SearchBarViewState extends State<SearchBarView> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      controller: widget.searchController,
      maxLength: widget.inputMaxLength ?? null,
      decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon ?? Icons.search_outlined,
            color: Colors.black87,
            size: 24,
          ),
          isDense: true,
          filled: true,
          hintText: widget.hintText,
          hintStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          )),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      onChanged: widget.onChanged,
    );
  }
}
