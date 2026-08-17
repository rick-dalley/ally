import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../classes/body_markers.dart';
import '../classes/body_zone.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/patient_pain.dart';
import '../classes/reminder_registry.dart';
import '../classes/symptom_care_plan.dart';
import '../classes/symptom_dismissal_reason.dart';
import '../classes/symptom_report.dart';
import '../widgets/body_marker_modal.dart';
import 'package:carbon_ui/widgets/carbon_button_compact.dart';
import '../widgets/report_preview_screen.dart';
import '../widgets/seek_care_sheet.dart';
import '../widgets/symptom_followup_dialog.dart';

enum FlipDirection { none, flipX, flipY, flipXY }

enum AnatomyMapTapped {
  none,
  body,
  rightHand,
  leftHand,
  rightFoot,
  leftFoot,
  face,
}

class BodyOutlineScreen extends StatefulWidget {
  final Patient patient;

  const BodyOutlineScreen({super.key, required this.patient});

  @override
  State<BodyOutlineScreen> createState() => _BodyOutlineScreenState();
}

class _BodyOutlineScreenState extends State<BodyOutlineScreen> {
  // Example: Store marker points here
  final List<BodyMarker> _markers = [];
  AnatomyZoneMaps selectedMap = AnatomyZoneMaps.bodyFront;
  FlipDirection imageOrientation = FlipDirection.none;
  TouchImage? touchImage;
  Widget? anatomyImage;
  AnatomyMapTapped anatomyMapTapped = AnatomyMapTapped.body;
  BodyMarkerGroup markerGroup = BodyMarkerGroup.bodyFront;
  // Wraps the diagram Stack (anatomy image + marker dots) so the send action can
  // capture exactly what's on screen — same image, same dots, no separate rendering
  // path to keep in sync with this one.
  final GlobalKey _diagramKey = GlobalKey();

  Offset orientOffset({
    required double height,
    required double width,
    required double imageHeight,
    required double imageWidth,
    required Offset offset,
    required FlipDirection flip,
    required AnatomyZoneMaps zoneMap,
  }) {
    // Define which maps support flipping
    final bool isFlippable = [
      AnatomyZoneMaps.handFront,
      AnatomyZoneMaps.handBack,
      AnatomyZoneMaps.footTop,
      AnatomyZoneMaps.footBottom,
    ].contains(zoneMap);

    if (!isFlippable || flip == FlipDirection.none) {
      return offset;
    }

    // Calculate new coordinates based on flip type
    double dx = (flip == FlipDirection.flipX || flip == FlipDirection.flipXY)
        ? width - offset.dx
        : offset.dx;

    double dy = (flip == FlipDirection.flipY || flip == FlipDirection.flipXY)
        ? height - offset.dy - ((height - imageHeight) * 0.5)
        : offset.dy;

    return Offset(dx, dy);
  }

  Zone _identifyZone(Offset tap) {
    for (var zone in touchImage!.zones) {
      if (zone.isIn(tap.dx, tap.dy) && zone.map == selectedMap) {
        //did the user tap on a zone that should bring up a map?
        if (zone.isLink) {
          setImageMapFromZone(zone);
          return touchImage!.zones.first;
        } else {
          return zone;
        }
      }
    }
    return touchImage!.zones.first;
  }

  void setImageMapFromZone(Zone zone) {
    AnatomyZoneMaps tappedMap = selectedMap;
    AnatomyMapTapped requested = anatomyMapTapped;
    FlipDirection selectedImageOrientation = imageOrientation;
    //did the user tap on a zone that should bring up a map?
    if (zone.name == "right hand") {
      requested = AnatomyMapTapped.rightHand;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront
          ? AnatomyZoneMaps.handFront
          : AnatomyZoneMaps.handBack;
      selectedImageOrientation = FlipDirection.flipX;
      markerGroup = BodyMarkerGroup.rightHandFront;
    } else if (zone.name == "left hand") {
      requested = AnatomyMapTapped.leftHand;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront
          ? AnatomyZoneMaps.handFront
          : AnatomyZoneMaps.handBack;
      selectedImageOrientation = FlipDirection.none;
      markerGroup = BodyMarkerGroup.leftHandFront;
    } else if (zone.name == "right foot") {
      requested = AnatomyMapTapped.rightFoot;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront
          ? AnatomyZoneMaps.footTop
          : AnatomyZoneMaps.footBottom;
      selectedImageOrientation = FlipDirection.flipX;
      markerGroup = BodyMarkerGroup.rightFootBottom;
    } else if (zone.name == "left foot") {
      requested = AnatomyMapTapped.rightFoot;
      tappedMap = selectedMap == AnatomyZoneMaps.bodyFront
          ? AnatomyZoneMaps.footTop
          : AnatomyZoneMaps.footBottom;
      selectedImageOrientation = FlipDirection.none;
      markerGroup = BodyMarkerGroup.leftFootBottom;
    } else if (zone.name == "face") {
      requested = AnatomyMapTapped.face;
      tappedMap = AnatomyZoneMaps.face;
      selectedImageOrientation = FlipDirection.none;
      markerGroup = BodyMarkerGroup.leftFootBottom;
    }
    setState(() {
      anatomyMapTapped = requested;
      selectedMap = tappedMap;
      imageOrientation = selectedImageOrientation;
      touchImage = TouchImageFactory.instance.getTouchImage(
        selection: selectedMap,
      )!;
      anatomyImage = touchImage!.flip(imageOrientation);
      debugPrint("$markerGroup");
    });
  }

  @override
  void initState() {
    super.initState();
    imageOrientation = FlipDirection.none;
    selectedMap = AnatomyZoneMaps.bodyFront;
    touchImage = TouchImageFactory.instance.getTouchImage(
      selection: selectedMap,
    );
    anatomyImage = touchImage?.flip(imageOrientation);
    _loadMarkers();
  }

  // Previously this screen never read from (or wrote to) the database at all — every
  // marker only ever lived in this in-memory list and vanished the moment the screen
  // closed. This is now the single source of truth on open.
  Future<void> _loadMarkers() async {
    final rows = await DatabaseManager().getMarkersForPatient(
      widget.patient.patientUuid,
    );
    // Resolved markers (dismissed, or resolved via a follow-up "It's Better") stay in
    // the database as history but shouldn't still look like an active symptom on the
    // map — nothing else in this screen shows a resolved/unresolved distinction visually.
    final loaded = rows
        .map((row) => BodyMarker.fromRow(row))
        .where((marker) => !marker.resolved)
        .toList();
    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(loaded);
    });
    _checkFollowUps();
  }

  // No push-notification system exists in this app, so "follow up in a few days" can
  // only mean "ask the next time they open this screen." Processes one due marker at
  // a time — each answer updates that marker's resolved/last_checked_at state, so the
  // same one won't come up again on the next pass, and the loop naturally terminates.
  Future<void> _checkFollowUps() async {
    final due = await DatabaseManager().getMarkersDueForFollowUp(
      widget.patient.patientUuid,
    );
    if (!mounted || due.isEmpty) return;

    final marker = BodyMarker.fromRow(due.first);
    final bool? handled = await showDialog<bool>(
      context: context,
      builder: (context) => SymptomFollowUpDialog(
        patientUuid: widget.patient.patientUuid,
        marker: marker,
      ),
    );

    // Dismissed without picking an option (tapped outside/back) — don't immediately
    // re-show the same prompt in a loop; ask again next time they open this screen.
    if (!mounted || handled != true) return;
    await ReminderRegistry.instance.refresh();
    await _loadMarkers();
  }

  // Shared by both creating a new marker (tapped an empty zone) and editing an
  // existing one (tapped a marker already on the map) — the only difference is
  // whether onSave inserts a new row or updates the one the patient already has.
  void _openMarkerModal({required BodyMarker marker, required bool isNew}) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => BodyMarkerModal(
        initialMarker: marker,
        onSave: (updatedMarker) async {
          if (isNew) {
            await DatabaseManager().insertBodyMarker(
              widget.patient.patientUuid,
              updatedMarker.toRow(),
            );
          } else {
            await DatabaseManager().updateBodyMarker(
              updatedMarker.id!,
              updatedMarker.toRow(),
            );
          }
          await _loadMarkers();
        },
        onSeekCare: _handleSeekCare,
        onDismiss: (dismissedMarker, reason) async {
          // A marker that was never saved (isNew) has no row to remove — closing the
          // modal (already done by BodyMarkerModal itself) is the whole action.
          if (isNew) return;
          if (reason == SymptomDismissalReason.createdByMistake) {
            await DatabaseManager().deleteBodyMarker(dismissedMarker.id!);
          } else {
            await DatabaseManager().resolveBodyMarker(
              dismissedMarker.id!,
              reason: reason.name,
            );
          }
          await _loadMarkers();
        },
      ),
    );
  }

  void _handleSeekCare(BodyMarker marker, SymptomCarePlan plan) {
    if (plan == SymptomCarePlan.call911) {
      _confirmAndCall911();
      return;
    }
    final SeekCareSheetMode mode = switch (plan) {
      SymptomCarePlan.phoneForAdvice => SeekCareSheetMode.advice,
      SymptomCarePlan.seekImmediateHelp => SeekCareSheetMode.urgent,
      SymptomCarePlan.scheduleAppointment => SeekCareSheetMode.schedule,
      SymptomCarePlan.ignoreForNow ||
      SymptomCarePlan.keepCheckingIn ||
      SymptomCarePlan.call911 => SeekCareSheetMode.schedule,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SeekCareSheet(
        patientUuid: widget.patient.patientUuid,
        bodyPart: marker.name,
        mode: mode,
        severity: marker.severity,
        frequency: marker.frequency,
      ),
    );
  }

  // A real emergency call needs a confirmation step — this can't be one accidental
  // tap away, unlike every other action in this dialog chain.
  Future<void> _confirmAndCall911() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Call 911?", style: CarbonTheme.carbonHeadingTextStyle),
              const SizedBox(height: 8),
              Text(
                "This will dial emergency services right now.",
                style: CarbonTheme.carbonHintTextStyle,
              ),
              const SizedBox(height: 24),
              CarbonCompactButton(
                icon: Symbols.emergency,
                label: "Call 911 Now",
                style: CarbonButtonStyle.danger,
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              CarbonCompactButton(
                icon: Symbols.close,
                label: "Cancel",
                style: CarbonButtonStyle.ghost,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      final Uri uri = Uri(scheme: 'tel', path: '911');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  // Captures the diagram exactly as currently rendered (image + marker dots) —
  // RepaintBoundary.toImage rather than redrawing the map from scratch in the PDF,
  // so the report always matches what the patient was actually looking at.
  Future<Uint8List?> _captureDiagram() async {
    final RenderRepaintBoundary? boundary =
        _diagramKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List();
  }

  Future<void> _sendReport() async {
    if (_markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No symptoms are currently tracked to report."),
        ),
      );
      return;
    }
    final Uint8List? diagramImage = await _captureDiagram();
    if (!mounted) return;
    final List<BodyMarker> currentGroupMarkers = _markers
        .where((m) => m.group == markerGroup)
        .toList();
    final List<BodyMarker> otherMarkers = _markers
        .where((m) => m.group != markerGroup)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          title: "Symptom Report",
          buildPdf: () => SymptomReport.build(
            patient: widget.patient,
            currentGroup: markerGroup,
            currentGroupMarkers: currentGroupMarkers,
            otherMarkers: otherMarkers,
            diagramImage: diagramImage,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (touchImage == null) {
      return Text("Touch Image not found!");
    }

    MediaQueryData mq = MediaQuery.of(context);
    final double notchPadding = mq.padding.top > 0 ? mq.padding.top : 47.0;

    return MediaQuery(
      data: mq.copyWith(padding: mq.padding.copyWith(top: notchPadding)),
      child: Scaffold(
        // Scaffold gives us full screen control
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          primary: true,
          title: Text("${widget.patient.firstName} ${widget.patient.lastName}"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              onPressed: _sendReport,
              icon: Icon(Symbols.send, size: 30),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            color: Color(0xFFFFFFFF),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ROW OF ICON BUTTONS TO CHOOSE ANATOMY
                Flexible(
                  fit: FlexFit.loose,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // These are your TRUE dimensions for hit testing
                      final double containerWidth = constraints.maxWidth;
                      final double containerHeight = constraints.maxHeight;
                      Size size = touchImage!.getSizeFromContainer();
                      return RepaintBoundary(
                        key: _diagramKey,
                        child: Stack(
                          fit: StackFit.loose,
                          children: [
                            GestureDetector(
                              onTapDown: (TapDownDetails details) {
                                Offset tapPosition = details.localPosition;
                                tapPosition = orientOffset(
                                  height: containerHeight,
                                  width: containerWidth,
                                  imageHeight: size.height,
                                  imageWidth: size.width,
                                  offset: tapPosition,
                                  flip: imageOrientation,
                                  zoneMap: selectedMap,
                                );
                                final zone = _identifyZone(tapPosition);

                                if (zone.name == "none" || zone.name.isEmpty) {
                                  return;
                                }
                                final newMarker = BodyMarker(
                                  offset: details.localPosition,
                                  emoji: PainLevel.distracting,
                                  name: zone.name,
                                  medicalName: zone.latin,
                                  zoneMap: zone.map,
                                  group: markerGroup,
                                );
                                _openMarkerModal(
                                  marker: newMarker,
                                  isNew: true,
                                );
                              },
                              child: Align(
                                alignment: Alignment.center,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  switchInCurve: Curves.easeInOut,
                                  switchOutCurve: Curves.easeInOut,
                                  transitionBuilder:
                                      (
                                        Widget child,
                                        Animation<double> animation,
                                      ) {
                                        final rotateAnim = Tween(
                                          begin: pi / 2,
                                          end: 0.0,
                                        ).animate(animation);
                                        return AnimatedBuilder(
                                          animation: rotateAnim,
                                          child: child,
                                          builder: (context, child) {
                                            return Transform(
                                              transform: Matrix4.identity()
                                                ..setEntry(
                                                  3,
                                                  2,
                                                  0.001,
                                                ) // Perspective
                                                ..rotateY(rotateAnim.value),
                                              alignment: Alignment.center,
                                              child: child,
                                            );
                                          },
                                        );
                                      },
                                  // KeyedSubtree forces the animation to re-run whenever 'selectedMap' changes
                                  child: KeyedSubtree(
                                    key: ValueKey(selectedMap),
                                    child: anatomyImage!,
                                  ),
                                ),
                              ),
                            ),

                            // Positioned.fill(
                            //   child: CustomPaint(
                            //     painter: PolygonPainter(
                            //       touchImage!,
                            //       imageOrientation,
                            //       mq.size.width,
                            //       mq.size.height,
                            //       size.height,
                            //     ),
                            //   ),
                            // ),
                            ..._markers
                                .where((marker) => marker.group == markerGroup)
                                .map(
                                  (marker) => Positioned(
                                    // A 44x44 tap target centered on the same point the
                                    // 24px dot is drawn at — the dot alone is too small
                                    // to reliably tap to reopen and update a symptom.
                                    left: marker.offset.dx - 22,
                                    top: marker.offset.dy - 22,
                                    width: 44,
                                    height: 44,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _openMarkerModal(
                                        marker: marker,
                                        isNew: false,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.circle,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: AppTheme.surfaceColor,
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Symbols.accessibility,
                  size: anatomyMapTapped == AnatomyMapTapped.body ? 36 : 30,
                  color: anatomyMapTapped == AnatomyMapTapped.body
                      ? AppTheme.primaryColor
                      : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    anatomyMapTapped = AnatomyMapTapped.body;
                    selectedMap = AnatomyZoneMaps.bodyFront;
                    touchImage = TouchImageFactory.instance.getTouchImage(
                      selection: selectedMap,
                    )!;
                    anatomyImage = touchImage?.flip(imageOrientation);
                    markerGroup = BodyMarkerGroup.bodyFront;
                  });
                },
              ),
              //Right Hand
              IconButton(
                icon: Icon(
                  Symbols.front_hand,
                  size: anatomyMapTapped == AnatomyMapTapped.rightHand
                      ? 36
                      : 30,
                  color: anatomyMapTapped == AnatomyMapTapped.rightHand
                      ? AppTheme.primaryColor
                      : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    anatomyMapTapped = AnatomyMapTapped.rightHand;
                    selectedMap = AnatomyZoneMaps.handFront;
                    imageOrientation = FlipDirection.flipX;
                    touchImage = TouchImageFactory.instance.getTouchImage(
                      selection: selectedMap,
                    )!;
                    anatomyImage = touchImage?.flip(imageOrientation);
                    markerGroup = BodyMarkerGroup.rightHandFront;
                  });
                },
              ),
              //Left Hand
              IconButton(
                icon: Transform.flip(
                  flipX: true,
                  child: Icon(
                    Symbols.front_hand,
                    size: anatomyMapTapped == AnatomyMapTapped.leftHand
                        ? 36
                        : 30,
                    color: anatomyMapTapped == AnatomyMapTapped.leftHand
                        ? AppTheme.primaryColor
                        : Colors.black,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    anatomyMapTapped = AnatomyMapTapped.leftHand;
                    selectedMap = AnatomyZoneMaps.handFront;
                    imageOrientation = FlipDirection.none;
                    touchImage = TouchImageFactory.instance.getTouchImage(
                      selection: selectedMap,
                    )!;
                    anatomyImage = touchImage?.flip(imageOrientation);
                    markerGroup = BodyMarkerGroup.leftHandFront;
                  });
                },
              ),
              IconButton(
                icon: Transform.flip(
                  flipY: true,
                  child: Icon(
                    Symbols.barefoot,
                    size: anatomyMapTapped == AnatomyMapTapped.rightFoot
                        ? 36
                        : 30,
                    color: anatomyMapTapped == AnatomyMapTapped.rightFoot
                        ? AppTheme.primaryColor
                        : Colors.black,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    anatomyMapTapped = AnatomyMapTapped.rightFoot;
                    selectedMap = AnatomyZoneMaps.footBottom;
                    imageOrientation = FlipDirection.flipX;
                    touchImage = TouchImageFactory.instance.getTouchImage(
                      selection: selectedMap,
                    )!;
                    anatomyImage = touchImage?.flip(imageOrientation);
                    markerGroup = BodyMarkerGroup.rightFootBottom;
                  });
                },
              ),
              IconButton(
                icon: Transform.flip(
                  flipX: true,
                  flipY: true,
                  child: Icon(
                    Symbols.barefoot,
                    size: anatomyMapTapped == AnatomyMapTapped.leftFoot
                        ? 36
                        : 30,
                    color: anatomyMapTapped == AnatomyMapTapped.leftFoot
                        ? AppTheme.primaryColor
                        : Colors.black,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    anatomyMapTapped = AnatomyMapTapped.leftFoot;
                    selectedMap = AnatomyZoneMaps.footBottom;
                    imageOrientation = FlipDirection.none;
                    touchImage = TouchImageFactory.instance.getTouchImage(
                      selection: selectedMap,
                    )!;
                    anatomyImage = touchImage?.flip(imageOrientation);
                    markerGroup = BodyMarkerGroup.leftFootBottom;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Symbols.face,
                  size: anatomyMapTapped == AnatomyMapTapped.face ? 36 : 30,
                  color: anatomyMapTapped == AnatomyMapTapped.face
                      ? AppTheme.primaryColor
                      : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    anatomyMapTapped = AnatomyMapTapped.face;
                    selectedMap = AnatomyZoneMaps.face;
                    touchImage = TouchImageFactory.instance.getTouchImage(
                      selection: selectedMap,
                    )!;
                    anatomyImage = touchImage?.flip(imageOrientation);
                    markerGroup = BodyMarkerGroup.face;
                  });
                },
              ),
              Spacer(),

              //Flip
              IconButton(
                icon: Icon(Symbols.flip, size: 30),
                onPressed: () {
                  AnatomyZoneMaps tappedMap = selectedMap;
                  BodyMarkerGroup tappedMarkerGroup = markerGroup;
                  switch (anatomyMapTapped) {
                    case AnatomyMapTapped.body:
                      {
                        imageOrientation = FlipDirection.none;
                        tappedMap = selectedMap == AnatomyZoneMaps.bodyBack
                            ? AnatomyZoneMaps.bodyFront
                            : AnatomyZoneMaps.bodyBack;
                        tappedMarkerGroup =
                            markerGroup == BodyMarkerGroup.bodyBack
                            ? BodyMarkerGroup.bodyFront
                            : BodyMarkerGroup.bodyBack;
                      }
                    case AnatomyMapTapped.face:
                      {
                        imageOrientation = FlipDirection.none;
                        tappedMap = AnatomyZoneMaps.face;
                        tappedMarkerGroup = BodyMarkerGroup.face;
                      }
                    case AnatomyMapTapped.rightHand:
                      {
                        imageOrientation = FlipDirection.flipX;
                        tappedMap = selectedMap == AnatomyZoneMaps.handBack
                            ? AnatomyZoneMaps.handFront
                            : AnatomyZoneMaps.handBack;
                        tappedMarkerGroup =
                            markerGroup == BodyMarkerGroup.rightHandFront
                            ? BodyMarkerGroup.rightHandBack
                            : BodyMarkerGroup.rightHandFront;
                      }
                    case AnatomyMapTapped.leftHand:
                      {
                        imageOrientation = FlipDirection.none;
                        tappedMap = selectedMap == AnatomyZoneMaps.handFront
                            ? AnatomyZoneMaps.handBack
                            : AnatomyZoneMaps.handFront;
                        tappedMarkerGroup =
                            markerGroup == BodyMarkerGroup.leftHandFront
                            ? BodyMarkerGroup.leftHandBack
                            : BodyMarkerGroup.leftHandFront;
                      }
                      tappedMarkerGroup =
                          markerGroup == BodyMarkerGroup.bodyBack
                          ? BodyMarkerGroup.bodyFront
                          : BodyMarkerGroup.bodyBack;
                    case AnatomyMapTapped.rightFoot:
                      {
                        imageOrientation = FlipDirection.flipX;
                        tappedMap = selectedMap == AnatomyZoneMaps.footBottom
                            ? AnatomyZoneMaps.footTop
                            : AnatomyZoneMaps.footBottom;
                        tappedMarkerGroup =
                            markerGroup == BodyMarkerGroup.rightFootBottom
                            ? BodyMarkerGroup.rightFootTop
                            : BodyMarkerGroup.rightFootBottom;
                      }
                    case AnatomyMapTapped.leftFoot:
                      {
                        imageOrientation = FlipDirection.none;
                        tappedMap = selectedMap == AnatomyZoneMaps.footBottom
                            ? AnatomyZoneMaps.footTop
                            : AnatomyZoneMaps.footBottom;
                        tappedMarkerGroup =
                            markerGroup == BodyMarkerGroup.leftFootBottom
                            ? BodyMarkerGroup.leftFootTop
                            : BodyMarkerGroup.leftFootBottom;
                      }
                    case AnatomyMapTapped.none:
                      {
                        tappedMap == selectedMap;
                        tappedMarkerGroup = BodyMarkerGroup.none;
                      }
                  }
                  setState(() {
                    selectedMap = tappedMap;
                    touchImage = TouchImageFactory.instance.getTouchImage(
                      selection: selectedMap,
                    )!;
                    anatomyImage = touchImage?.flip(imageOrientation);
                    markerGroup = tappedMarkerGroup;
                  });
                  // Use a fixed duration for the flip to ensure it feels like a physical movement
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
