import 'package:melodix/core/service/permission_handling_service.dart';

/// Opens the app's page in the system settings, where access the user
/// turned off for good (music, videos) can be allowed again. Returns false
/// if the page couldn't be opened.
class OpenAppSettingsUseCase {
  const OpenAppSettingsUseCase(this._permissions);

  final PermissionHandlingService _permissions;

  Future<bool> call() => _permissions.openSettings();
}
