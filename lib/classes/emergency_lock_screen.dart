import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/emergency_qr.dart';
import 'patient.dart';

// Two different platform realities, not one cross-platform trick. Android genuinely
// lets an app draw over the lock screen without unlocking the device underneath — the
// same window behavior alarm and incoming-call screens use, so it gets a live view
// that's always current. Apple grants that to no third-party app, full stop, so iOS
// gets its own Lock Screen wallpaper instead: a real, Apple-sanctioned way to be
// visible without unlocking, but a static snapshot the patient has to redo by hand if
// their allergies, conditions, or emergency contact change.
class EmergencyLockScreen {
  static const MethodChannel _channel = MethodChannel(
    'com.example.ally/lock_screen',
  );

  static Future<void> _setShowOverLockScreen(bool enabled) async {
    try {
      await _channel.invokeMethod('setShowOverLockScreen', {
        'enabled': enabled,
      });
    } catch (_) {
      // Best-effort — on a device/OS version that doesn't support this, the screen
      // still opens normally underneath, just without the lock-screen bypass.
    }
  }

  // The single entry point UserScreen calls — it decides which platform behavior
  // applies so callers don't have to know the difference.
  static Future<void> present(BuildContext context, Patient patient) async {
    if (Platform.isIOS) {
      await _saveAsWallpaper(context, patient);
      return;
    }
    await _presentLive(context, patient);
  }

  static Future<void> _presentLive(
    BuildContext context,
    Patient patient,
  ) async {
    await _setShowOverLockScreen(true);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EmergencyQRCodeView(householdMember: patient),
      ),
    );
    await _setShowOverLockScreen(false);
  }

  static Future<void> _saveAsWallpaper(
    BuildContext context,
    Patient patient,
  ) async {
    final Uint8List png = await _renderQrPng(patient);
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/emergency_qr_wallpaper.png');
    await file.writeAsBytes(png);

    if (!context.mounted) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text:
            'Save this photo, then set it as your Lock Screen wallpaper in '
            'Settings > Wallpaper so emergency responders can see it without '
            'unlocking your phone.',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Set as your Lock Screen'),
        content: const Text(
          'After saving the photo: open Settings > Wallpaper > Add New '
          'Wallpaper, choose the QR code you just saved, and set it as your '
          'Lock Screen.\n\n'
          "Remember to redo this if your allergies, conditions, or emergency "
          "contact change — the wallpaper won't update on its own.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // White background is drawn explicitly — QrPainter itself only paints the modules
  // onto a transparent canvas, which would be unreliable to scan (or invisible) once
  // set as a Lock Screen wallpaper that might sit over a dark background image.
  static Future<Uint8List> _renderQrPng(Patient patient) async {
    final Map<String, dynamic> payload =
        await EmergencyQRCodeView.buildEmergencyPayload(patient);
    const double qrSize = 1024;
    const double margin = 96;
    const double canvasSize = qrSize + margin * 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.save();
    canvas.translate(margin, margin);
    QrPainter(
      data: jsonEncode(payload),
      version: QrVersions.auto,
      gapless: true,
    ).paint(canvas, const Size(qrSize, qrSize));
    canvas.restore();

    final ui.Image image = await recorder.endRecording().toImage(
      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}
