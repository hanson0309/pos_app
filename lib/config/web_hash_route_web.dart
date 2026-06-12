import 'dart:html' as html;
import 'routes.dart';

bool _suppressHashListener = false;

bool get isWebHashNavigationSuppressed => _suppressHashListener;

void suppressWebHashNavigation(void Function() action) {
  _suppressHashListener = true;
  try {
    action();
  } finally {
    Future.microtask(() => _suppressHashListener = false);
  }
}

String webHashToRoute() {
  var hash = html.window.location.hash;
  if (hash.isEmpty || hash == '#') return AppRoutes.cashier;
  var path = hash.startsWith('#') ? hash.substring(1) : hash;
  if (!path.startsWith('/')) path = '/$path';
  if (AppRoutes.parseReceiptClaimRoute(path) != null) return path;
  return AppRoutes.cashier;
}

void setWebHashRoute(String route) {
  final path = route.startsWith('/') ? route : '/$route';
  suppressWebHashNavigation(() {
    html.window.history.replaceState(null, '', '${html.window.location.pathname}#$path');
  });
}

/// Browser back/forward only (not fired by our [setWebHashRoute]).
void listenWebHashRoute(void Function(String route) onRoute) {
  html.window.onPopState.listen((_) {
    if (_suppressHashListener) return;
    onRoute(webHashToRoute());
  });
}
