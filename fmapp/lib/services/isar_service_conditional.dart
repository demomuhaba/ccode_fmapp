// Export the appropriate IsarService based on platform
export 'isar_service.dart' if (dart.library.html) 'isar_service_web_stub.dart';