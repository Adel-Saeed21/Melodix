import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Remembers whether the user has finished onboarding (the intro pages and
/// the look), so returning users go straight to the library.
///
/// Uses the app's existing [HydratedStorage], initialised in `main` before
/// `runApp`, so no extra storage dependency is needed.
class OnboardingService {
  OnboardingService._();

  static const String _key = 'onboarding_completed';

  static bool get isCompleted => HydratedBloc.storage.read(_key) == true;

  static Future<void> markCompleted() => HydratedBloc.storage.write(_key, true);
}
