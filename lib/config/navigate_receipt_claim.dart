import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'routes.dart';
import 'web_hash_route.dart';

/// Opens the public e-invoice claim flow (web: in-app + hash; mobile: browser).
Future<void> openReceiptClaimUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  var path = uri.fragment;
  if (path.isEmpty) path = uri.path;
  if (!path.startsWith('/')) path = '/$path';
  if (AppRoutes.parseReceiptClaimRoute(path) == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid claim URL')),
      );
    }
    return;
  }

  if (kIsWeb) {
    final root = Navigator.of(context, rootNavigator: true);
    root.popUntil((route) {
      final n = route.settings.name;
      return n == AppRoutes.cashier || route.isFirst;
    });
    setWebHashRoute(path);
    await root.pushNamed(path);
    return;
  }

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open claim URL')),
      );
    }
  }
}
