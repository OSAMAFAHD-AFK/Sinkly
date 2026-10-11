import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/local_storage_service.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../models/auth_user_model.dart';
import 'auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl({required AuthRemoteDataSource remoteDataSource, required this._storage}) : _remote = remoteDataSource;

  final AuthRemoteDataSource _remote;
  final LocalStorageService _storage;

  @override
  AuthUserModel? currentUser() => _remote.currentUser();

  @override
  AppStartDestination resolveStartDestination() =>
      _storage.plan.onboardingCompleted ? AppStartDestination.home : AppStartDestination.onboarding;

  @override
  Future<Either<Failure, AuthUserModel>> signIn(AuthProviderType provider) async {
    try {
      return right(await _remote.signIn(provider));
    } catch (error) {
      return left(ServerFailure('error_sign_in', debugMessage: '$error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remote.signOut();
      return right(unit);
    } catch (error) {
      return left(ServerFailure('error_generic', debugMessage: '$error'));
    }
  }
}
