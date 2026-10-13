import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_start_destination_model.dart';
import '../../data/repos/splash_repo.dart';

/// Session gate behind the splash animation: emits where to go once the
/// brand animation has played (`null` while it is still playing).
class SplashCubit extends Cubit<AppStartDestination?> {
  SplashCubit(this._repo) : super(null);

  final SplashRepo _repo;

  void resolveStartDestination() => emit(_repo.resolveStartDestination());
}
