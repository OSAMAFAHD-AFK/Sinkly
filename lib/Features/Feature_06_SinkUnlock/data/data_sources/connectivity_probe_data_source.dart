import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../../core/utils/app_constants.dart';

/// "Is there REAL internet right now?" — asked before opening the camera, so
/// nobody takes a photo that can't be checked.
///
/// A connected Wi-Fi without internet still says "connected" to the OS, so
/// this makes one tiny request to our own server instead. Any HTTP answer
/// (even an error code) means the internet works.
abstract class ConnectivityProbeDataSource {
  Future<bool> hasInternet();
}

class HttpConnectivityProbeDataSource implements ConnectivityProbeDataSource {
  HttpConnectivityProbeDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<bool> hasInternet() async {
    // Not set up yet: the offline mock checks photos, nothing to probe.
    if (AppConstants.supabaseUrl.isEmpty) return true;
    try {
      await _client
          .head(Uri.parse('${AppConstants.supabaseUrl}/auth/v1/health'))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }
}
