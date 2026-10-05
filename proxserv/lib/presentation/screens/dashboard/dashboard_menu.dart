import 'package:flutter/material.dart';

class DashboardMenuScope extends InheritedWidget {
  final VoidCallback onOpenDrawer;

  const DashboardMenuScope({
    super.key,
    required this.onOpenDrawer,
    required super.child,
  });

  static VoidCallback? maybeOpenDrawer(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DashboardMenuScope>()
        ?.onOpenDrawer;
  }

  @override
  bool updateShouldNotify(DashboardMenuScope oldWidget) =>
      onOpenDrawer != oldWidget.onOpenDrawer;
}

class DashboardMenuButton extends StatelessWidget {
  const DashboardMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final openDrawer = DashboardMenuScope.maybeOpenDrawer(context);
    if (openDrawer == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: openDrawer,
      icon: const Icon(Icons.menu),
    );
  }
}

Widget? dashboardMenuLeading(BuildContext context) {
  if (MediaQuery.sizeOf(context).width >= 600 ||
      DashboardMenuScope.maybeOpenDrawer(context) == null) {
    return null;
  }
  return const DashboardMenuButton();
}
