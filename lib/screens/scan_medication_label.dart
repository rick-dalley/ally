import 'dart:io';

import 'package:camera/camera.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import 'package:carbon_ui/widgets/carbon_style_autocomplete.dart';
import 'package:carbon_ui/widgets/carbon_style_full_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_theme.dart';
import '../classes/drug_name_matcher.dart';
import '../classes/medication_label_scanner.dart';
import '../classes/medication_services.dart';

/// Photographs a dispensed medication label and resolves it against the bundled drug
/// vocabulary.
///
/// It does not try to parse the label. Layouts vary by pharmacy and by country and
/// there is no grammar to lean on — an earlier version that tried confidently reported
/// a pharmacy chain's name as the medication. What it does instead is hand every line
/// OCR returned to [DrugNameMatcher], which knows what a drug is called, and offers
/// back whatever the vocabulary recognised. The person taps the right one.
///
/// That also survives the curve of the bottle: a long name wrapping out of sight still
/// leaves a fragment at the front, and a fragment resolves against a known vocabulary.
class ScanMedicationLabel extends StatefulWidget {
  const ScanMedicationLabel({super.key});

  @override
  State<ScanMedicationLabel> createState() => _ScanMedicationLabelState();
}

class _ScanMedicationLabelState extends State<ScanMedicationLabel> with WidgetsBindingObserver {
  final MedicationLabelScanner _scanner = MedicationLabelScanner();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  CameraController? _camera;
  bool _permissionDenied = false;

  ScannedMedicationLabel? _result;
  List<DrugNameSuggestion> _candidates = const [];
  List<String> _recognizedLines = const [];
  DosageUnit? _unit;
  bool _isReading = false;
  bool _readFailed = false;
  bool _showAllLines = false;

  bool get _hasResult => _result != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _scanner.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Android reclaims the camera when the app goes to the background; coming back to a
  // dead controller shows a frozen last frame with a shutter button that does nothing.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasResult && state == AppLifecycleState.resumed && _camera == null) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
      _camera = null;
    }
  }

  Future<void> _startCamera() async {
    final PermissionStatus status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty || !mounted) return;

    final CameraController controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _camera = controller);
  }

  Future<void> _capture() async {
    if (_isReading) return;
    final CameraController? controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    final XFile shot = await controller.takePicture();
    await _readLabel(File(shot.path));
  }

  // A real path on the iOS Simulator, which has no camera at all, and a reasonable
  // option on a device too.
  Future<void> _pickFromGallery() async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _readLabel(File(picked.path));
  }

  Future<void> _readLabel(File image) async {
    setState(() {
      _isReading = true;
      _readFailed = false;
    });

    final ScannedMedicationLabel? parsed = await _scanner.scanImageFile(image.path);
    if (!mounted) return;

    final List<String> lines = (parsed?.rawText ?? '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final List<DrugNameSuggestion> candidates = drugNames.suggestFromLines(lines);

    setState(() {
      _isReading = false;
      _recognizedLines = lines;
      _candidates = candidates;

      if (parsed == null || lines.isEmpty) {
        _readFailed = true;
        _result = null;
        return;
      }

      _result = parsed;
      // The vocabulary's best guess wins over anything the parser thought, and the
      // person confirms it either way.
      _nameController.text = candidates.isNotEmpty ? candidates.first.name : (parsed.name ?? '');
      _amountController.text = parsed.amount ?? '';
      _unit = parsed.unit;
    });
  }

  void _confirm() {
    final ScannedMedicationLabel? parsed = _result;
    if (parsed == null) return;

    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(
      context,
      parsed.copyWith(
        name: name,
        amount: _amountController.text.trim().isEmpty ? null : _amountController.text.trim(),
        unit: _unit,
      ),
    );
  }

  void _retake() {
    setState(() {
      _result = null;
      _readFailed = false;
      _candidates = const [];
      _recognizedLines = const [];
      _showAllLines = false;
      _nameController.clear();
      _amountController.clear();
      _unit = null;
    });
    if (_camera == null) _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    // The capture step runs full bleed on black with its controls pinned to the
    // bottom; the review step is an ordinary form. Two different jobs, two layouts.
    return _hasResult ? _buildReviewScaffold() : _buildCaptureScaffold();
  }

  // --- Capture -------------------------------------------------------------

  Widget _buildCaptureScaffold() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Scan the label"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Text(
              "Point at the printed label, not the barcode. If the name wraps around "
              "the bottle, show the START of it — the first few letters are what count.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          // The preview takes whatever is left after the hint and the controls, so the
          // shutter is always on screen at a fixed place. It used to sit ABOVE a tall
          // fixed-ratio preview, which put it out of thumb reach and meant holding the
          // phone in two hands with the bottle standing on the counter — exactly the
          // thing you cannot do while holding a pill bottle.
          Expanded(child: _buildPreview()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CarbonFullButton(
                    label: _isReading ? 'READING…' : 'CAPTURE',
                    icon: Symbols.photo_camera,
                    style: CarbonButtonStyle.primary,
                    size: CarbonButtons.large,
                    // CarbonFullButton's onTap is non-nullable, and a no-op closure
                    // for "disabled" is the anti-pattern its own docs call out — it
                    // looks identical to enabled. Guarded inside _capture instead,
                    // with the label and the preview spinner carrying the busy state.
                    onTap: _capture,
                  ),
                  const SizedBox(height: 8),
                  CarbonCompactButton(
                    label: "Choose a photo instead",
                    icon: Symbols.photo_library,
                    style: CarbonButtonStyle.ghost,
                    onTap: _isReading ? null : _pickFromGallery,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isReading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_permissionDenied) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Ally needs the camera to read a label. You can still pick a photo from "
              "your library below.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            CarbonCompactButton(
              label: "Open Settings",
              icon: Symbols.settings,
              style: CarbonButtonStyle.tertiary,
              onTap: openAppSettings,
            ),
          ],
        ),
      );
    }

    final CameraController? controller = _camera;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_readFailed) {
      return Stack(
        fit: StackFit.expand,
        children: [CameraPreview(controller), _buildFailureOverlay()],
      );
    }

    return CameraPreview(controller);
  }

  Widget _buildFailureOverlay() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: const Center(
        child: Text(
          "Couldn't make out that label. Try more light, hold a little steadier, or "
          "move closer so the name fills more of the frame.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // --- Review --------------------------------------------------------------

  Widget _buildReviewScaffold() {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        title: const Text("Check this"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(CarbonSpacing.wide.width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_candidates.isNotEmpty) ..._buildCandidatePicker(),
              ..._buildNameAndStrength(),
              ..._buildRecognizedLines(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: CarbonCompactButton(
                      icon: Symbols.refresh,
                      label: "Retake",
                      style: CarbonButtonStyle.secondary,
                      onTap: _retake,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CarbonCompactButton(
                      icon: Symbols.check,
                      label: "Use this",
                      style: CarbonButtonStyle.primary,
                      onTap: _confirm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCandidatePicker() {
    return [
      Text("Which one is it?", style: CarbonTheme.carbonHeadingTextStyle),
      const SizedBox(height: 8),
      Text(
        "These are the medications we recognised on the label.",
        style: CarbonTheme.carbonHintTextStyle,
      ),
      const SizedBox(height: 16),
      for (final DrugNameSuggestion candidate in _candidates) ...[
        CarbonFullButton(
          label: candidate.name,
          icon: Symbols.medication,
          style: candidate.name == _nameController.text
              ? CarbonButtonStyle.primary
              : CarbonButtonStyle.tertiary,
          onTap: () => setState(() => _nameController.text = candidate.name),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildNameAndStrength() {
    final ScannedMedicationLabel parsed = _result!;

    return [
      // Type-ahead rather than a plain box: if none of the candidates is right, a few
      // letters still resolves the name without spelling it out.
      CarbonAutocomplete(
        label: "Medication name",
        controller: _nameController,
        placeholder: "Start typing if none of these are right",
        filter: (String query) => drugNames.suggest(query),
      ),
      const SizedBox(height: 16),
      Text("Strength", style: CarbonTheme.carbonLabelTextStyle),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DosageUnit.values.map((unit) {
                final bool isSelected = unit == _unit;
                return GestureDetector(
                  onTap: () => setState(() => _unit = unit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryColor,
                      border: Border.all(
                        color: isSelected ? carbonColorBorderInteractive : AppTheme.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      unit.label,
                      style: TextStyle(
                        color: isSelected ? carbonColorInteractive : AppTheme.defaultFontColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      if (parsed.directions != null) ...[
        const SizedBox(height: 16),
        Text("Directions on the label", style: CarbonTheme.carbonLabelTextStyle),
        const SizedBox(height: 4),
        Text(parsed.directions!, style: TextStyle(color: AppTheme.defaultFontColor)),
      ],
    ];
  }

  /// Everything OCR read, behind a toggle. This is the escape hatch when the
  /// vocabulary recognised nothing — the name is in there somewhere, and tapping the
  /// line that holds it beats retyping it.
  List<Widget> _buildRecognizedLines() {
    if (_recognizedLines.isEmpty) return const [];

    return [
      const SizedBox(height: 24),
      InkWell(
        onTap: () => setState(() => _showAllLines = !_showAllLines),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                _showAllLines ? Symbols.expand_less : Symbols.expand_more,
                color: carbonColorInteractive,
                size: 20,
              ),
              const SizedBox(width: 8),
              // Flexible with a wrapping label: a fixed-width string here ran off the
              // side of the screen at 360dp.
              Flexible(
                child: Text(
                  _candidates.isEmpty ? "Pick the name off the label" : "Something else on the label",
                  style: TextStyle(color: carbonColorInteractive),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_showAllLines)
        for (final String line in _recognizedLines)
          InkWell(
            onTap: () => setState(() => _nameController.text = line),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Text(line, style: TextStyle(color: AppTheme.defaultFontColor), softWrap: true),
            ),
          ),
    ];
  }
}
