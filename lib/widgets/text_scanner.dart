import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_style_full_button.dart';

import '../app_theme.dart';

class TextScanner extends StatefulWidget {
  final Function(RecognizedText) onTextDetected;
  final String?
  mockImagePath; // If passed, we OCR this instead of the live feed

  const TextScanner({
    super.key,
    required this.onTextDetected,
    this.mockImagePath,
  });

  @override
  State<TextScanner> createState() => _TextScannerState();
}

class _TextScannerState extends State<TextScanner> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isPermissionGranted = false;
  // iOS only ever shows its camera dialog once per install. After a "Don't Allow" —
  // or on a bundle id that was denied under an earlier build — request() returns
  // immediately with no prompt, which looked from the outside like the app simply
  // never asked. Tracked separately so that case gets a way out (Settings) rather
  // than the same dead-end "permission required" text as the not-yet-asked case.
  bool _isPermanentlyDenied = false;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.mockImagePath != null) {
      _processMockImage();
    } else {
      _requestCameraPermission();
    }
  }

  // Simulation mode used to OCR an actual bundled license photo, which meant the demo
  // depended on shipping that image in the app bundle. It's synthesized directly now —
  // same shape of result IntakeScreen's parser expects (surname line ending in a comma,
  // first name on the next line, a "DOB:" line, a PHN-shaped number), just fabricated
  // in code instead of read off a photo. Keeps the demo working with nothing to ship
  // and nothing that can fail to load.
  Future<void> _processMockImage() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    widget.onTextDetected(
      RecognizedText(
        text: 'DALLEY,\nRICHARD\nDOB: 1978-MAR-22\n1234 567 890',
        blocks: [],
      ),
    );
  }

  // --- Camera Lifecycle & Permissions ---
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _isPermissionGranted = status.isGranted;
      // isRestricted covers parental/MDM restrictions — the person can't grant it from
      // Settings either, so it gets the same explanatory treatment rather than a
      // button that would take them somewhere with nothing to toggle.
      _isPermanentlyDenied = status.isPermanentlyDenied || status.isRestricted;
    });
    if (_isPermissionGranted) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller?.initialize();
    if (!mounted) return;
    setState(() {});

    // Start the stream for live document detection
    _controller?.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Logic for converting CameraImage to InputImage goes here
    // (similar to yesterday, but using a larger ROI)

    _isProcessing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mockImagePath != null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      );
    }

    if (!_isPermissionGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isPermanentlyDenied
                    ? "Ally doesn't have permission to use the camera."
                    : "Waiting for camera permission…",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onPrimaryColor),
              ),
              if (_isPermanentlyDenied) ...[
                const SizedBox(height: 8),
                Text(
                  "iOS only asks once. Turn the camera on for Ally in Settings and come back.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.onPrimaryColor),
                ),
                const SizedBox(height: 24),
                CarbonFullButton(
                  label: 'OPEN SETTINGS',
                  icon: Symbols.settings,
                  style: CarbonButtonStyle.tertiary,
                  onTap: openAppSettings,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: 3 / 4, // More suitable for documents than a square
      child: Stack(
        fit: StackFit.expand,
        children: [CameraPreview(_controller!), _buildDocumentOverlay()],
      ),
    );
  }

  Widget _buildDocumentOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: _DocumentOverlayShape(
          borderColor: Colors.indigoAccent,
          borderWidth: 3.0,
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "ALIGN DOCUMENT WITHIN FRAME",
            style: TextStyle(
              color: Colors.indigoAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;

  const _DocumentOverlayShape({
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // A vertical document-style frame
    final frameRect = Rect.fromLTWH(
      rect.width * 0.1,
      rect.height * 0.1,
      rect.width * 0.8,
      rect.height * 0.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
      paint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
