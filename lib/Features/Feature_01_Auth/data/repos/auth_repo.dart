import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/auth_user_model.dart';

/// Where the app should go after the splash screen.
enum AppStartDestination { onboarding, home }

abstract class AuthRepo {
  AuthUserModel? currentUser();
  AppStartDestination resolveStartDestination();
  Future<Either<Failure, AuthUserModel>> signIn(AuthProviderType provider);
  Future<Either<Failure, Unit>> signOut();
}
