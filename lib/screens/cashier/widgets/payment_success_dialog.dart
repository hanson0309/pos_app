import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/receipt.dart';
import '../../../services/printer_service.dart';
import 'print_error_dialog.dart';

class PaymentSuccessDialog extends StatefulWidget {
  final String transactionNumber;
  final double totalAmount;
  final double changeAmount;
  final String paymentMethod;
  final Receipt? receipt;
  final VoidCallback onNewTransaction;
  final VoidCallback? onPrinterSettings;

  const PaymentSuccessDialog({
    super.key,
    required this.transactionNumber,
    required this.totalAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.receipt,
    required this.onNewTransaction,
    this.onPrinterSettings,
  });

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  final PrinterService _printerService = PrinterService();
  bool _isPrinting = false;

  Future<void> _handlePrintReceipt() async {
    if (widget.receipt == null) {
      _showErrorDialog('No receipt data available');
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final success = await _printerService.printReceiptNew(widget.receipt!);

      if (mounted) {
        setState(() {
          _isPrinting = false;
        });

        if (success) {
          _showSuccessSnackBar('Receipt printed successfully');
        } else {
          _showPrintErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
        _showPrintErrorDialog();
      }
    }
  }

  void _showPrintErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => PrintErrorDialog(
        errorMessage: _printerService.lastError ?? 'Unknown error occurred',
        onRetry: () {
          _handlePrintReceipt();
        },
        onSkip: () {
          // Just close the dialog
        },
        onSettings: () {
          if (widget.onPrinterSettings != null) {
            widget.onPrinterSettings!();
          }
        },
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Error'),
        content: Text(message, style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
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
            // Success Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.successGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transaction #${widget.transactionNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction Details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildDetailRow('Total Amount', 'RM ${widget.totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Payment Method', _getPaymentMethodLabel()),
                  if (widget.paymentMethod == 'cash' && widget.changeAmount > 0) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Change',
                      'RM ${widget.changeAmount.toStringAsFixed(2)}',
                      highlight: true,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDetailRow('Date & Time', _getCurrentDateTime()),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Print Receipt Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : () {
                        _handlePrintReceipt();
                      },
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.print_rounded),
                      label: Text(_isPrinting ? 'Printing...' : 'Print Receipt'),
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
                  // New Transaction Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isPrinting ? null : () {
                        Navigator.of(context).pop();
                        widget.onNewTransaction();
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('New Transaction'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: highlight ? AppTheme.successColor : AppTheme.textSecondaryDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: highlight ? AppTheme.successColor : AppTheme.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel() {
    switch (widget.paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return widget.paymentMethod;
    }
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
