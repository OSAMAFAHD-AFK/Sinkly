part of 'auth_cubit.dart';

enum AuthStatus { idle, signingIn, signedIn, failure }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.idle, this.activeProvider, this.user, this.failureKey});

  final AuthStatus status;

  /// Which button shows the spinner while signing in.
  final AuthProviderType? activeProvider;
  final AuthUserModel? user;
  final String? failureKey;

  bool get isBusy => status == AuthStatus.signingIn;

  AuthState copyWith({AuthStatus? status, AuthProviderType? activeProvider, AuthUserModel? user, String? failureKey}) =>
      AuthState(
        status: status ?? this.status,
        activeProvider: activeProvider ?? this.activeProvider,
        user: user ?? this.user,
        failureKey: failureKey,
      );

  @override
  List<Object?> get props => [status, activeProvider, user, failureKey];
}
