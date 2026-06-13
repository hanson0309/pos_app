import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:network_info_plus/network_info_plus.dart';

class DiscoveredNetworkPrinter {
  final String host;
  final int port;

  const DiscoveredNetworkPrinter({required this.host, this.port = 9100});

  String get address => port == 9100 ? host : '$host:$port';
}

/// Probes the local Wi‑Fi subnet for ESC/POS printers (RAW TCP port 9100).
class NetworkPrinterDiscovery {
  static const int defaultPort = 9100;
  static const Duration _probeTimeout = Duration(milliseconds: 350);

  static Future<String?> localWifiIp() async {
    if (kIsWeb) return null;
    try {
      return await NetworkInfo().getWifiIP();
    } catch (_) {
      return null;
    }
  }

  static String? subnetFromIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  /// Scans 1–254 on the same subnet as [localIp]. Calls [onProgress] with 0.0–1.0.
  static Future<List<DiscoveredNetworkPrinter>> scan({
    String? localIp,
    int port = defaultPort,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Wi‑Fi printer scan is not available in the browser');
    }

    final ip = localIp ?? await localWifiIp();
    if (ip == null || ip.isEmpty) {
      throw Exception('Connect to Wi‑Fi to scan for printers on your network');
    }

    final subnet = subnetFromIp(ip);
    if (subnet == null) {
      throw Exception('Could not determine local network subnet');
    }

    final found = <DiscoveredNetworkPrinter>[];
    const batchSize = 40;
    final hosts = List.generate(254, (i) => '$subnet.${i + 1}');

    for (var start = 0; start < hosts.length; start += batchSize) {
      final end = (start + batchSize < hosts.length) ? start + batchSize : hosts.length;
      final batch = hosts.sublist(start, end);

      final probes = await Future.wait(
        batch.map((host) => _probe(host, port)),
      );

      for (final printer in probes) {
        if (printer != null) found.add(printer);
      }

      onProgress?.call(end / hosts.length);
    }

    found.sort((a, b) => _compareIp(a.host, b.host));
    return found;
  }

  static Future<DiscoveredNetworkPrinter?> _probe(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: _probeTimeout);
      await socket.close();
      return DiscoveredNetworkPrinter(host: host, port: port);
    } catch (_) {
      return null;
    }
  }

  static int _compareIp(String a, String b) {
    final pa = a.split('.').map(int.parse).toList();
    final pb = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 4; i++) {
      final d = pa[i] - pb[i];
      if (d != 0) return d;
    }
    return 0;
  }
}
