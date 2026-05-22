import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();
  }

  Future<void> _checkDeviceStatus() async {
    // 等待 2 秒显示启动页
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 检查是否已经配对
    final deviceToken = await _storage.read(key: Constants.keyDeviceToken);

    if (deviceToken != null && deviceToken.isNotEmpty) {
      // 已配对，直接跳转到收银页
      Navigator.pushReplacementNamed(context, '/cashier');
    } else {
      // 未配对，跳转到配对页
      Navigator.pushReplacementNamed(context, '/pairing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.point_of_sale,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'POS System',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Malaysia E-Invoice Integration',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
