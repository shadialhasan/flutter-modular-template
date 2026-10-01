/**
 * Production-Grade Flutter Modular Architecture Boilerplate
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

export 'core/errors/app_error_codes.dart';
export 'core/network/http_router.dart';
export 'core/network/network_models.dart';
export 'core/state/state_machine.dart';
export 'core/sync/sync_queue_persistence.dart';
export 'features/auth/domain/models/auth_user.dart';
export 'features/auth/presentation/auth_state_controller.dart';

// Architecture Blueprint:
// lib/
//   core/
//     errors/        -> Structured AppErrorCode and exceptions
//     network/       -> Modular HTTP routing & models
//     state/         -> State transition machine
//     sync/          -> Offline sync queue & persistence
//   features/
//     auth/
//       domain/      -> Auth models and entity representations
//       presentation/-> State machine controllers & view state
//     dashboard/

class AppConfig {
  static const String appName = "Enterprise Flutter App";
  static const String environment = "Production";
  static const String author = "Eng. MHD. Shadi AL-Hasan";
  static const String authorEmail = "mhd.shadi.alhasan@gmail.com";
  static const String authorPhone = "+963934005922";
  static const String authorLocation = "Damascus, Syria";
}

void main() {
  print("${AppConfig.appName} initialized - Modular Architecture Ready.");
}
