import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/app_config.dart';
import '../../../config/navigate_printer_settings.dart';
import '../../../config/theme.dart';
import '../../../models/transaction.dart';
import '../../../models/receipt.dart';
import '../../../services/transaction_service.dart';
import '../../../utils/constants.dart';
import '../providers/cart_provider.dart';
import 'payment_success_dialog.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final double totalAmount;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String _selectedPaymentMethod = 'cash';
  final TextEditingController _amountController = TextEditingController();
  double _receivedAmount = 0;
  double _changeAmount = 0;
  bool _isProcessing = false;

  final _transactionService = TransactionService.instance;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(2);
    _receivedAmount = widget.totalAmount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    setState(() {
      _receivedAmount = double.tryParse(_amountController.text) ?? 0;
      _changeAmount = _receivedAmount - widget.totalAmount;
    });
  }

  void _processPayment() async {
    if (_selectedPaymentMethod == 'cash' && _changeAmount < 0) {
      _showError('Insufficient amount received');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get cart items
      final cartNotifier = ref.read(cartProvider.notifier);
      final cartItems = ref.read(cartProvider);

      if (cartItems.isEmpty) {
        _showError('Cart is empty');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Convert cart items to transaction items
      final transactionItems = cartItems.map((cartItem) {
        final taxRate = 6.0; // 6% SST (as percentage, not decimal)
        final lineSubtotal = cartItem.product.price * cartItem.quantity;
        final lineTax = lineSubtotal * (taxRate / 100); // Convert percentage to decimal for calculation
        final lineTotal = lineSubtotal + lineTax;

        return TransactionItem(
          productId: cartItem.product.id ?? 'unknown',
          description: cartItem.product.name,
          quantity: cartItem.quantity,
          unitPrice: cartItem.product.price,
          taxType: 'SST',
          taxRate: taxRate,
          taxAmount: lineTax,
          lineTotal: lineTotal,
        );
      }).toList();

      // Calculate totals
      final subtotal = cartNotifier.subtotal;
      final discount = cartNotifier.discountAmount;
      final taxableAmount = subtotal - discount;
      final taxAmount = taxableAmount * 0.06; // 6% tax calculation
      final totalAmount = taxableAmount + taxAmount;

      // Process payment and create invoice
      final result = await _transactionService.processPayment(
        items: transactionItems,
        customerId: null, // TODO: Get from customer selection
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        paymentMethod: _selectedPaymentMethod,
        invoiceType: '01', 
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (result.success && result.transaction != null) {
        const storage = FlutterSecureStorage();
        final tenantId = await storage.read(key: Constants.keyTenantId);
        final receiptNo = result.transaction!.transactionNumber;
        final claimUrl = AppConfig.buildReceiptClaimUrl(
          receiptNo,
          tenantId: tenantId,
        );

        // Create receipt object
        final receipt = Receipt(
          transactionNumber: receiptNo,
          transactionDate: result.transaction!.transactionDate,
          storeName: 'POS System', // TODO: load from tenant/POS settings API
          storeAddress: null,
          storePhone: null,
          taxNumber: null,
          einvoiceClaimUrl: claimUrl,
          invoiceId: result.invoiceId,
          items: cartItems.map((item) => ReceiptItem(
            name: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.price,
            lineTotal: item.lineTotal,
          )).toList(),
          subtotal: subtotal,
          discount: discount,
          discountLabel: cartNotifier.discountLabel,
          serviceTax: 0,
          serviceTaxRate: 0,
          tax: taxAmount,
          taxRate: 6.0,
          total: totalAmount,
          paymentMethod: _selectedPaymentMethod,
          receivedAmount: _receivedAmount,
          changeAmount: _changeAmount,
        );

        // Close payment dialog
        if (mounted) {
          Navigator.of(context).pop(true);
        }

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PaymentSuccessDialog(
              transactionNumber: result.transaction!.transactionNumber,
              totalAmount: totalAmount,
              changeAmount: _changeAmount,
              paymentMethod: _selectedPaymentMethod,
              receipt: receipt,
              onNewTransaction: () {
                cartNotifier.clear();
                widget.onPaymentComplete();
              },
              onPrinterSettings: () => openPrinterSettings(context),
            ),
          );
        }

        // Show sync status
        if (!result.syncedImmediately) {
          _showWarning('Payment completed. Invoice will be synced when online.');
        }
      } else {
        _showError(result.error ?? 'Failed to process payment');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showError('Error: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.accentOrange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
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
            // Header
            _buildHeader(),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Amount Display
                    _buildTotalAmount(),

                    const SizedBox(height: 32),

                    // Payment Method Selection
                    _buildPaymentMethods(),

                    const SizedBox(height: 32),

                    // Cash Payment Input
                    if (_selectedPaymentMethod == 'cash') ...[
                      _buildCashInput(),
                      const SizedBox(height: 24),
                      _buildQuickAmounts(),
                      const SizedBox(height: 24),
                      _buildChangeDisplay(),
                    ],

                    // Card/E-wallet info
                    if (_selectedPaymentMethod != 'cash') ...[
                      _buildNonCashInfo(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Process Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select payment method and complete transaction',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          Text(
            'RM ${widget.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                'cash',
                'Cash',
                Icons.payments_rounded,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodCard(
                'card',
                'Card',
                Icons.credit_card_rounded,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodCard(
                'ewallet',
                'E-Wallet',
                Icons.account_balance_wallet_rounded,
                AppTheme.accentOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    String method,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : AppTheme.surfaceLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.cardBorderColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : AppTheme.textSecondaryDark,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount Received',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryDark,
          ),
          decoration: InputDecoration(
            prefixText: 'RM ',
            prefixStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondaryDark,
            ),
            filled: true,
            fillColor: AppTheme.surfaceLight.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.cardBorderColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.cardBorderColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) => _calculateChange(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmounts() {
    final quickAmounts = [50.0, 100.0, 200.0, 500.0];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: quickAmounts.map((amount) {
        return InkWell(
          onTap: () {
            setState(() {
              _amountController.text = amount.toStringAsFixed(2);
              _calculateChange();
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.cardBorderColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              'RM ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChangeDisplay() {
    final isNegative = _changeAmount < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNegative
            ? AppTheme.errorColor.withOpacity(0.1)
            : AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNegative
              ? AppTheme.errorColor.withOpacity(0.3)
              : AppTheme.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNegative ? 'Insufficient' : 'Change',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isNegative ? AppTheme.errorColor : AppTheme.successColor,
            ),
          ),
          Text(
            'RM ${_changeAmount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isNegative ? AppTheme.errorColor : AppTheme.successColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonCashInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            _selectedPaymentMethod == 'card'
                ? Icons.credit_card_rounded
                : Icons.qr_code_rounded,
            size: 64,
            color: AppTheme.textSecondaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedPaymentMethod == 'card'
                ? 'Insert or tap card on terminal'
                : 'Scan QR code to pay',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for payment confirmation...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(
                  color: AppTheme.cardBorderColor.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _isProcessing ? null : _processPayment,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: _isProcessing ? null : AppTheme.successGradient,
                  color: _isProcessing ? AppTheme.textSecondaryDark : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isProcessing ? null : [
                    BoxShadow(
                      color: AppTheme.successColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      _isProcessing ? 'Processing...' : 'Complete Payment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
