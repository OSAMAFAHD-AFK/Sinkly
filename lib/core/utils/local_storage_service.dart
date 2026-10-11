import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/shared_core_models.dart';

/// Single source of truth for on-device persistence.
///
/// Every feature data source reads/writes through this service, and cubits
/// subscribe to [planChanges] / [sessionsChanges] so all tabs stay in sync
/// without passing state between features.
class LocalStorageService {
  LocalStorageService(this._preferences) : _plan = _readPlan(_preferences), _sessions = _readSessions(_preferences);

  final SharedPreferences _preferences;

  static const String _planKey = 'sinkly.user_plan';
  static const String _sessionsKey = 'sinkly.sink_sessions';

  UserPlanModel _plan;
  List<SinkCleaningSessionModel> _sessions;

  final StreamController<UserPlanModel> _planController = StreamController.broadcast();
  final StreamController<List<SinkCleaningSessionModel>> _sessionsController = StreamController.broadcast();

  // ── User plan ──────────────────────────────────────────────────────────
  UserPlanModel get plan => _plan;
  Stream<UserPlanModel> get planChanges => _planController.stream;

  Future<void> savePlan(UserPlanModel plan) async {
    if (plan == _plan) return;
    _plan = plan;
    _planController.add(plan);
    await _preferences.setString(_planKey, jsonEncode(plan.toJson()));
  }

  // ── Cleaning sessions ──────────────────────────────────────────────────
  List<SinkCleaningSessionModel> get sessions => _sessions;
  Stream<List<SinkCleaningSessionModel>> get sessionsChanges => _sessionsController.stream;

  Future<void> addSession(SinkCleaningSessionModel session) async {
    _sessions = List.unmodifiable([..._sessions, session]);
    _sessionsController.add(_sessions);
    await _preferences.setString(_sessionsKey, jsonEncode(_sessions.map((s) => s.toJson()).toList()));
  }

  // ── Generic key/value helpers for small feature flags ──────────────────
  String? getString(String key) => _preferences.getString(key);
  Future<void> setString(String key, String value) => _preferences.setString(key, value);
  bool getBool(String key, {bool fallback = false}) => _preferences.getBool(key) ?? fallback;
  Future<void> setBool(String key, bool value) => _preferences.setBool(key, value);
  List<String> getStringList(String key) => _preferences.getStringList(key) ?? const [];
  Future<void> setStringList(String key, List<String> value) => _preferences.setStringList(key, value);

  /// Wipes everything (used by "Reset Sinkly" in settings).
  Future<void> clearAll() async {
    await _preferences.clear();
    _plan = UserPlanModel.initial(languageCode: _plan.languageCode);
    _sessions = const [];
    _planController.add(_plan);
    _sessionsController.add(_sessions);
  }

  static UserPlanModel _readPlan(SharedPreferences preferences) {
    final raw = preferences.getString(_planKey);
    if (raw == null) return UserPlanModel.initial();
    try {
      return UserPlanModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserPlanModel.initial();
    }
  }

  static List<SinkCleaningSessionModel> _readSessions(SharedPreferences preferences) {
    final raw = preferences.getString(_sessionsKey);
    if (raw == null) return const [];
    try {
      return List.unmodifiable(
        (jsonDecode(raw) as List).map(
          (item) => SinkCleaningSessionModel.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      );
    } catch (_) {
      return const [];
    }
  }
}
