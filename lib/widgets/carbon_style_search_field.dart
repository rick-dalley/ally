import 'package:flutter/material.dart';

class CarbonSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function onChanged;
  const CarbonSearchField({super.key, required this.controller, required this.onChanged});

  @override
  State<StatefulWidget> createState() => CarbonSearchFieldState();
}

class CarbonSearchFieldState extends State<CarbonSearchField> {
  late TextEditingController controller = widget.controller;
  String searchTerm = "";
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchTerm = ""; // Reset the query
                            controller.clear();
                          });
                        },
                      )
                    : null, // No icon if the field is empty
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
              onChanged: (value) {
                widget.onChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
