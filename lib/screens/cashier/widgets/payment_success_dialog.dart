import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/app_config.dart';
import '../../../config/theme.dart';
import '../../../models/receipt.dart';
import '../../../services/printer_service.dart';
import '../../../services/receipt_debug_service.dart';
import '../../../utils/constants.dart';
import 'print_error_dialog.dart';
import 'receipt_emulator_preview_dialog.dart';

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
  final _storage = const FlutterSecureStorage();
  bool _isPrinting = false;
  bool _debugEmulatorReady = false;

  @override
  void initState() {
    super.initState();
    _printerService.addListener(_onPrinterServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDialogReady());
  }

  @override
  void dispose() {
    _printerService.removeListener(_onPrinterServiceChanged);
    super.dispose();
  }

  void _onPrinterServiceChanged() {
    if (mounted) setState(() {});
  }

  bool get _showPrinting =>
      _isPrinting || _printerService.isPrinting;

  Future<void> _onDialogReady() async {
    if (AppConfig.useReceiptEmulator && !_printerService.isConnected) {
      await _initDebugEmulator();
    }

    final autoPrint = _printerService.activePrinter?.autoPrintReceipt ?? false;
    if (!mounted || !autoPrint || widget.receipt == null) return;
    if (!_printerService.isConnected) return;

    // Print in background so payment success UI is instant.
    _handlePrintReceipt(silent: true);
  }

  Future<void> _initDebugEmulator() async {
    final tenantId = await _storage.read(key: Constants.keyTenantId);
    if (tenantId == null || !mounted) return;

    final ok = await ReceiptDebugService.instance.ensureEmulator(tenantId);
    if (!mounted) return;

    setState(() => _debugEmulatorReady = ok);
  }

  Future<void> _handlePrintReceipt({bool silent = false}) async {
    if (widget.receipt == null) {
      if (!silent) _showErrorDialog('No receipt data available');
      return;
    }

    if (_showPrinting) {
      if (!silent) {
        _showSuccessSnackBar('Printer is busy, please wait…');
      }
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _isPrinting = true;
      });
    }

    try {
      if (AppConfig.useReceiptEmulator && !_printerService.isConnected) {
        final tenantId = await _storage.read(key: Constants.keyTenantId);
        if (tenantId != null) {
          await ReceiptDebugService.instance.ensureEmulator(tenantId);
        }
      }

      final success = await _printerService.printReceiptNew(widget.receipt!);

      if (!mounted) return;

      if (!silent) {
        setState(() {
          _isPrinting = false;
        });
      }

      if (success) {
        if (!silent) {
          if (AppConfig.useReceiptEmulator &&
              _printerService.lastEmulatorFilePath != null) {
            _showSuccessSnackBar(
              'Debug: receipt saved (${_printerService.lastEmulatorFilePath})',
            );
          } else {
            _showSuccessSnackBar('Receipt printed successfully');
          }
        }
      } else if (!silent) {
        _showPrintErrorDialog();
      }
    } catch (e) {
      if (mounted && !silent) {
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

  void _showPreviewReceipt() {
    if (widget.receipt == null) {
      _showErrorDialog('No receipt data available');
      return;
    }
    ReceiptEmulatorPreviewDialog.show(
      context,
      receipt: widget.receipt!,
      onPrintToEmulator: AppConfig.useReceiptEmulator
          ? () async {
              await _handlePrintReceipt();
            }
          : (_printerService.isConnected ? () async => _handlePrintReceipt() : null),
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: maxHeight),
        child: Container(
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
              // Success header (fixed)
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
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (AppConfig.useReceiptEmulator)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bug_report, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _debugEmulatorReady
                                      ? 'Debug mode: receipt emulator available'
                                      : 'Debug mode: setting up receipt emulator…',
                                  style: AppTheme.bodySmall.copyWith(color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Total Amount',
                              'RM ${widget.totalAmount.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Payment Method',
                              _getPaymentMethodLabel(),
                            ),
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

                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showPrinting ? null : _showPreviewReceipt,
                                icon: const Icon(Icons.receipt_long_rounded),
                                label: const Text('Preview receipt'),
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
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showPrinting ? null : () => _handlePrintReceipt(),
                                icon: _showPrinting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.print_rounded),
                                label: Text(
                                  _showPrinting
                                      ? 'Printing...'
                                      : AppConfig.useReceiptEmulator
                                          ? 'Save receipt (debug)'
                                          : _printerService.isConnected
                                              ? 'Print receipt'
                                              : 'Print (set up printer)',
                                ),
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
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
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
              ),
            ],
          ),
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: highlight ? AppTheme.successColor : AppTheme.textSecondaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlight ? AppTheme.successColor : AppTheme.textPrimaryDark,
              ),
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
