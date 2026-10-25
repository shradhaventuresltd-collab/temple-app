import 'package:flutter/widgets.dart';

/// Home's scroll offset, shared with the drawer and the Home icons.
///
/// [HomeScreen] attaches the controller for the collage scroll view.
/// Drawer Home, the list Home icon, and detail Home call [animateToTop]
/// so returning to Home shows the photo collage instead of the previous offset.
class HomeScroll {
  HomeScroll._();

  static ScrollController? controller;

  static void attach(ScrollController value) {
    controller = value;
  }

  static void detach(ScrollController value) {
    if (identical(controller, value)) controller = null;
  }

  /// Animates the attached Home list to the top.
  ///
  /// A list or detail route can cover Home, so the scroll view may not be
  /// laid out in the same turn as the pop. Wait until it has a client.
  static Future<void> animateToTop() async {
    for (var frame = 0; frame < 30; frame++) {
      final scroll = controller;
      if (scroll != null && scroll.hasClients) {
        if (scroll.offset == 0) return;
        await scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
    }
  }
}
