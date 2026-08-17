import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';
import 'package:carbon_ui/widgets/carbon_style_textbox.dart';

class AvatarPicker extends StatefulWidget {
  /// Passes back the raw Uint8List bytes so you can save them as a BLOB in SQLite.
  final Function(Uint8List?) onPicked;

  /// Optional initial bytes if loading an existing image out of SQLite.
  final Uint8List? rawImage;

  const AvatarPicker({super.key, required this.onPicked, this.rawImage});

  @override
  State<StatefulWidget> createState() => AvatarPickerState();
}

class AvatarPickerState extends State<AvatarPicker> {
  DecorationImage? _decorationImage;
  Uint8List? _currentBytes;
  bool _hasError = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.rawImage != null && widget.rawImage!.isNotEmpty) {
      _currentBytes = widget.rawImage;
      _decorationImage = DecorationImage(image: MemoryImage(_currentBytes!), fit: BoxFit.cover);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _hasError = false;
        _currentBytes = bytes;
        _decorationImage = DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover);
      });
      widget.onPicked(_currentBytes);
    }
  }

  Future<void> _setFromUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    // Fetch the bytes over the network once so we can cache them permanently in SQLite
    try {
      final response = await http.get(Uri.parse(trimmed));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final bytes = response.bodyBytes;
        setState(() {
          _hasError = false;
          _currentBytes = bytes;
          _decorationImage = DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover);
        });
        widget.onPicked(_currentBytes);
        return;
      }
    } catch (_) {
      // Fallback or handle network drop/invalid URI cleanly below
    }

    // If fetch failed or returned non-200 (like LinkedIn 999 block)
    setState(() {
      _decorationImage = null;
      _currentBytes = null;
      _hasError = true;
    });
    widget.onPicked(null);
  }

  void _showSourceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Symbols.photo_library),
                title: const Text('Choose from Photos / Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Symbols.link),
                title: const Text('Download & Store Image URL'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => ImageUrlInputDialog(onSave: _setFromUrl),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSourceSelector(context),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: carbonColorField,
          border: Border.all(color: carbonColorBorderStrong03),
          borderRadius: BorderRadius.zero,
          image: _decorationImage,
        ),
        child: _decorationImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.add_a_photo, size: CarbonIcons.large.size.width, color: carbonColorBorderStrong03),
                  if (_hasError) ...[
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Not a valid image',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              )
            : null,
      ),
    );
  }
}

class ImageUrlInputDialog extends StatefulWidget {
  final Function(String) onSave;
  const ImageUrlInputDialog({super.key, required this.onSave});

  @override
  State<ImageUrlInputDialog> createState() => _ImageUrlInputDialogState();
}

class _ImageUrlInputDialogState extends State<ImageUrlInputDialog> {
  final TextEditingController uriController = TextEditingController();

  @override
  void dispose() {
    uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: const Text("Enter Image URL"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [CarbonTextInput(label: "Direct Image Link", controller: uriController)],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: CarbonButton(
                label: "Cancel",
                style: CarbonButtonStyle.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: CarbonButton(
                label: "Download",
                onPressed: () {
                  if (uriController.text.trim().isNotEmpty) {
                    widget.onSave(uriController.text);
                  }
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
