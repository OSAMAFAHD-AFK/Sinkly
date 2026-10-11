import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/auth_user_model.dart';
import '../../data/repos/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(AuthState(user: _repo.currentUser()));

  final AuthRepo _repo;

  AppStartDestination resolveStartDestination() => _repo.resolveStartDestination();

  Future<bool> signIn(AuthProviderType provider) async {
    if (state.isBusy) return false;
    emit(state.copyWith(status: AuthStatus.signingIn, activeProvider: provider));
    final result = await _repo.signIn(provider);
    return result.fold(
      (failure) {
        emit(state.copyWith(status: AuthStatus.failure, failureKey: failure.messageKey));
        return false;
      },
      (user) {
        emit(state.copyWith(status: AuthStatus.signedIn, user: user));
        return true;
      },
    );
  }
}
