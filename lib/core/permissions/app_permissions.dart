// Central permission helper.
//
// One place to ask for runtime permissions. Every feature that needs
// camera / gallery / contacts / etc. should go through here rather than
// calling `Permission.foo.request()` directly so the "permanently
// denied → open Settings" fallback UX stays consistent.
//
// Why this exists:
//   • iOS only lets the system prompt the user ONCE. After that, the
//     request silently returns `denied` and the app has to send the user
//     to Settings → App → enable. The naive `await permission.request()`
//     pattern misses this and looks broken.
//   • Android post-12L has a separate "denied" vs "permanentlyDenied"
//     state. Same handling.
//   • Some permissions cascade (e.g. asking for camera implicitly grants
//     microphone if video — but image_picker doesn't need this).
//
// The wrapper returns a tri-state result so callers can branch:
//
//   PermissionOutcome.granted          → proceed
//   PermissionOutcome.denied           → user said no this time; can ask again
//   PermissionOutcome.permanentlyDenied→ must send to Settings
//
// Example:
//
//   final outcome = await AppPermissions.ensure(AppPermission.camera);
//   if (outcome.isGranted) { /* open camera */ }
//   else if (outcome.isPermanentlyDenied) {
//     // Show a SnackBar with an "Open Settings" action.
//     openAppSettings();
//   }

import 'package:permission_handler/permission_handler.dart';

/// Stable, app-level names for the permissions we ask for. Adding a new
/// permission means adding a case to [_resolve] below.
enum AppPermission {
  camera,
  photos,        // gallery / photo library read
  microphone,
  location,
  contacts,
  notifications,
  storage,       // for file_picker non-image files (PDFs, etc) on older Androids
}

enum PermissionOutcome {
  granted,
  denied,
  permanentlyDenied,
  /// Restricted by parental controls (iOS) or device admin (Android).
  restricted,
}

extension PermissionOutcomeX on PermissionOutcome {
  bool get isGranted => this == PermissionOutcome.granted;
  bool get isPermanentlyDenied => this == PermissionOutcome.permanentlyDenied;
}

class AppPermissions {
  AppPermissions._();

  /// Ask for [p] and return the resolved outcome. Safe to call repeatedly
  /// — if already granted, returns instantly.
  static Future<PermissionOutcome> ensure(AppPermission p) async {
    final permission = _resolve(p);
    var status = await permission.status;
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    if (status.isRestricted) return PermissionOutcome.restricted;

    status = await permission.request();
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    if (status.isRestricted) return PermissionOutcome.restricted;
    return PermissionOutcome.denied;
  }

  /// Open the system Settings app on the gum_flutter entry. Use this
  /// when the user has permanently denied a permission and the only way
  /// forward is for them to flip it manually.
  static Future<bool> openSettings() => openAppSettings();

  static Permission _resolve(AppPermission p) {
    switch (p) {
      case AppPermission.camera:        return Permission.camera;
      case AppPermission.photos:        return Permission.photos;
      case AppPermission.microphone:    return Permission.microphone;
      case AppPermission.location:      return Permission.locationWhenInUse;
      case AppPermission.contacts:      return Permission.contacts;
      case AppPermission.notifications: return Permission.notification;
      case AppPermission.storage:       return Permission.storage;
    }
  }
}
