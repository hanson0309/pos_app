import 'routes.dart';

bool get isWebHashNavigationSuppressed => false;

void suppressWebHashNavigation(void Function() action) => action();

String webHashToRoute() => AppRoutes.cashier;

void setWebHashRoute(String route) {}

void listenWebHashRoute(void Function(String route) onRoute) {}
