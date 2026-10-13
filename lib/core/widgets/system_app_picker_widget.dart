import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/style.dart';
import 'custom_card_container.dart';

/// iOS: Apple's own FamilyActivityPicker (Screen Time API) embedded in our
/// screen — the only way an iOS app may let users pick apps. Apple renders
/// the categories/apps; we only receive opaque tokens, which the native side
/// (AppDelegate.swift) stores for ManagedSettings shields.
///
/// [onCountChanged] gets apps + categories + websites picked, live.
class SystemAppPickerWidget extends StatefulWidget {
  const SystemAppPickerWidget({super.key, required this.onCountChanged, this.height = 520});

  final ValueChanged<int> onCountChanged;
  final double height;

  static const String viewType = 'sinkly/family_activity_picker';
  static const MethodChannel channel = MethodChannel('sinkly/screen_time');

  @override
  State<SystemAppPickerWidget> createState() => _SystemAppPickerWidgetState();
}

class _SystemAppPickerWidgetState extends State<SystemAppPickerWidget> {
  @override
  void initState() {
    super.initState();
    SystemAppPickerWidget.channel.setMethodCallHandler((call) async {
      if (call.method == 'selectionChanged') widget.onCountChanged(_count(call.arguments));
    });
    SystemAppPickerWidget.channel
        .invokeMethod<Object?>('getSelectionSummary')
        .then((summary) {
          if (mounted) widget.onCountChanged(_count(summary));
        })
        .catchError((Object _) {});
  }

  static int _count(Object? arguments) {
    final map = arguments is Map ? arguments : const {};
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return read('apps') + read('categories') + read('webDomains');
  }

  @override
  void dispose() {
    SystemAppPickerWidget.channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.cardAll,
        child: SizedBox(
          height: widget.height,
          child: const UiKitView(
            viewType: SystemAppPickerWidget.viewType,
            creationParamsCodec: StandardMessageCodec(),
            // The native list scrolls itself; let it own vertical drags.
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
            },
          ),
        ),
      ),
    );
  }
}
