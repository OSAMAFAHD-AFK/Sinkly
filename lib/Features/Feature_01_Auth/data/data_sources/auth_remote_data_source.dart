import 'dart:convert';

import '../../../../core/utils/local_storage_service.dart';
import '../models/auth_user_model.dart';

/// Authentication provider contract.
///
/// Firebase wiring plan:
///  * Apple  — `sign_in_with_apple` → `OAuthProvider('apple.com').credential(...)`
///             → `FirebaseAuth.instance.signInWithCredential`.
///  * Google — `google_sign_in` → `GoogleAuthProvider.credential(...)`.
///  * Guest  — `FirebaseAuth.instance.signInAnonymously()` (can be linked later).
abstract class AuthRemoteDataSource {
  AuthUserModel? currentUser();
  Future<AuthUserModel> signIn(AuthProviderType provider);
  Future<void> signOut();
}

/// Local mock that simulates sign-in latency and remembers the session.
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  MockAuthRemoteDataSource(this._storage);

  final LocalStorageService _storage;
  static const String _sessionKey = 'sinkly.mock_auth_session';

  @override
  AuthUserModel? currentUser() {
    final raw = _storage.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthUserModel> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final user = AuthUserModel(
      uid: 'mock_${provider.name}_${DateTime.now().millisecondsSinceEpoch}',
      provider: provider,
      displayName: _storage.plan.displayName,
    );
    await _storage.setString(_sessionKey, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<void> signOut() => _storage.setString(_sessionKey, '');
}
