import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class PrintErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  final VoidCallback onSettings;

  const PrintErrorDialog({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onSkip,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.errorColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.print_disabled,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Print Failed',
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to print receipt',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // Error Details
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                  // Error Message Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 18,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Error Details',
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Troubleshooting Tips
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 18,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Troubleshooting Tips',
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Check if printer is turned on'),
                        const SizedBox(height: 6),
                        _buildTip('Verify Bluetooth connection'),
                        const SizedBox(height: 6),
                        _buildTip('Ensure printer has paper'),
                        const SizedBox(height: 6),
                        _buildTip('Try reconnecting the printer'),
                      ],
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Retry Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Settings Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSettings();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Printer Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: AppTheme.cardBorderColor.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Skip Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSkip();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Skip and Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textSecondaryDark,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ),
      ],
    );
  }
}
