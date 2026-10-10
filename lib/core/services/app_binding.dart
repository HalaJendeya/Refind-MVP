import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/memory_service.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/memory/memory_controller.dart';

/// Objects that live for the whole time the app is open.
/// Order matters: services first, then the controllers that use them.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<MemoryService>(MemoryService(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<MemoryController>(MemoryController(), permanent: true);
  }
}
