import 'package:get/get.dart';

/// Remembers which bottom-navigation tab is selected.
/// 0 = Home, 1 = Library, 2 = Favorites, 3 = Profile
class MainController extends GetxController {
  final RxInt tabIndex = 0.obs;

  void changeTab(int index) => tabIndex.value = index;
}
