import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';
import '../../services/api/endpoints.dart';
import '../../utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _pairingCodeController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();
  bool _isLoading = false;

  /// Generate a unique device ID
  /// Uses stored device_id if available, otherwise generates a new UUID
  Future<String> _getOrCreateDeviceId() async {
    // Try to get existing device_id from storage
    String? existingDeviceId = await _storage.read(key: 'device_uuid');

    if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
      return existingDeviceId;
    }

    // Generate new UUID and store it
    final newDeviceId = _uuid.v4();
    await _storage.write(key: 'device_uuid', value: newDeviceId);
    return newDeviceId;
  }

  /// Get OS information for the device
  String _getOsInfo() {
    if (kIsWeb) {
      return 'Web';
    } else {
      try {
        return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      } catch (e) {
        return 'Unknown';
      }
    }
  }

  Future<void> _pairDevice() async {
    final code = _pairingCodeController.text.trim().toUpperCase();

    if (code.isEmpty || code.length != 6) {
      _showError('Please enter a valid 6-digit pairing code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get or create unique device_id
      final deviceId = await _getOrCreateDeviceId();
      final osInfo = _getOsInfo();

      // Call pairing API with correct format
      final deviceApi = DeviceApi();
      final result = await deviceApi.pairDevice(
        pairingCode: code,
        deviceInfo: {
          'device_id': deviceId,  // Required: unique device identifier
          'os': osInfo,           // Optional: OS information
        },
      );

      // Save device token and IDs
      await _storage.write(
        key: Constants.keyDeviceToken,
        value: result['device_token'],
      );
      await _storage.write(
        key: Constants.keyDeviceId,
        value: result['device_id'],
      );
      await _storage.write(
        key: Constants.keyTenantId,
        value: result['tenant_id'],
      );

      if (mounted) {
        // Pairing successful, navigate to login
        Navigator.pushReplacementNamed(context, '/login');
        _showSuccess('Device paired successfully!');
      }
    } catch (e) {
      _showError('Pairing failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _pairingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Pairing'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 120,
                color: Color(0xFF2196F3),
              ),
              const SizedBox(height: 32),
              const Text(
                'Pair Your Device',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the 6-digit pairing code from your admin panel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _pairingCodeController,
                decoration: InputDecoration(
                  labelText: 'Pairing Code',
                  hintText: 'IB4KNG',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pairDevice,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Pair Device'),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'API: http://localhost:3000/api/v1',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
