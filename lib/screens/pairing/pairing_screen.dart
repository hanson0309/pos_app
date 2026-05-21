import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';
import '../../services/api/endpoints.dart';
import '../../utils/constants.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
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

      // Handle different response structures
      String? deviceIdToSave;
      String? tenantIdToSave;

      // Check if device_id is at root level or needs to use the one we sent
      if (result.containsKey('device_id')) {
        deviceIdToSave = result['device_id'];
      } else {
        deviceIdToSave = deviceId; // Use the one we sent
      }

      // Check if tenant_id is at root level or in tenant_info
      if (result.containsKey('tenant_id')) {
        tenantIdToSave = result['tenant_id'];
      } else if (result.containsKey('tenant_info') &&
                 result['tenant_info'] is Map &&
                 result['tenant_info']['tenant_id'] != null) {
        tenantIdToSave = result['tenant_info']['tenant_id'];
      }

      await _storage.write(
        key: Constants.keyDeviceId,
        value: deviceIdToSave,
      );
      await _storage.write(
        key: Constants.keyTenantId,
        value: tenantIdToSave,
      );

      print('✅ Device paired successfully!');
      print('Device ID: $deviceIdToSave');
      print('Tenant ID: $tenantIdToSave');
      print('Token saved: ${result['device_token'] != null}');

      if (mounted) {
        // Pairing successful, navigate directly to cashier screen
        _showSuccess('Device paired successfully!');

        // Wait a moment for the success message to show
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/cashier');
        }
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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),

              // Title
              const Text(
                'Pair Your Device',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Enter the 6-digit pairing code from your admin panel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 48),

              // Pairing Code Input
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _pairingCodeController,
                  decoration: InputDecoration(
                    labelText: 'Pairing Code',
                    hintText: 'A1B2C3',
                    filled: true,
                    fillColor: AppTheme.surfaceLight.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.cardBorderColor.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.vpn_key_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryDark,
                  ),
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(height: 32),

              // Pair Button
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pairDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.textSecondaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link_rounded),
                            SizedBox(width: 12),
                            Text(
                              'Pair Device',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 48),

              // Info Card
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.cardBorderColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'How to get pairing code?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Login to admin panel\n'
                      '2. Go to POS Management → Devices\n'
                      '3. Click "Add New Device"\n'
                      '4. Copy the 6-digit code',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // API Info
              Text(
                'API: ${Uri.parse(AppConfig.apiBaseUrl).host}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryDark.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
