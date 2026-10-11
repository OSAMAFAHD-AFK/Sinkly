import 'package:equatable/equatable.dart';

enum AuthProviderType { apple, google, guest }

/// Signed-in account. Mirrors the fields we will read from `firebase_auth`'s
/// `User` once Firebase is wired (uid, displayName, email, provider).
class AuthUserModel extends Equatable {
  const AuthUserModel({required this.uid, required this.provider, this.displayName, this.email});

  final String uid;
  final AuthProviderType provider;
  final String? displayName;
  final String? email;

  bool get isGuest => provider == AuthProviderType.guest;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
    uid: json['uid'] as String,
    provider: AuthProviderType.values.firstWhere(
      (type) => type.name == json['provider'],
      orElse: () => AuthProviderType.guest,
    ),
    displayName: json['displayName'] as String?,
    email: json['email'] as String?,
  );

  Map<String, dynamic> toJson() => {'uid': uid, 'provider': provider.name, 'displayName': displayName, 'email': email};

  @override
  List<Object?> get props => [uid, provider, displayName, email];
}
