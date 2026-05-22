import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

class DiscountDialog extends StatefulWidget {
  final double currentTotal;
  final Function(double, String) onApplyDiscount;

  const DiscountDialog({
    super.key,
    required this.currentTotal,
    required this.onApplyDiscount,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  String _discountType = 'percentage'; // 'percentage' or 'fixed'
  final TextEditingController _discountController = TextEditingController();
  double _discountAmount = 0;
  double _finalAmount = 0;

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.currentTotal;
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _calculateDiscount() {
    final value = double.tryParse(_discountController.text) ?? 0;

    setState(() {
      if (_discountType == 'percentage') {
        _discountAmount = widget.currentTotal * (value / 100);
      } else {
        _discountAmount = value;
      }
      _finalAmount = widget.currentTotal - _discountAmount;

      // Ensure final amount is not negative
      if (_finalAmount < 0) {
        _finalAmount = 0;
        _discountAmount = widget.currentTotal;
      }
    });
  }

  void _applyDiscount() {
    if (_discountAmount <= 0) {
      _showError('Please enter a valid discount');
      return;
    }

    final discountLabel = _discountType == 'percentage'
        ? '${_discountController.text}% OFF'
        : 'RM ${_discountController.text} OFF';

    widget.onApplyDiscount(_discountAmount, discountLabel);
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentOrange, Colors.orange[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Apply Discount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Current Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Total',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondaryDark,
                          ),
                        ),
                        Text(
                          'RM ${widget.currentTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Discount Type Selection
                  const Text(
                    'Discount Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDiscountTypeCard(
                          'percentage',
                          'Percentage',
                          Icons.percent_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDiscountTypeCard(
                          'fixed',
                          'Fixed Amount',
                          Icons.attach_money_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Discount Input
                  const Text(
                    'Discount Value',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryDark,
                    ),
                    decoration: InputDecoration(
                      prefixText: _discountType == 'fixed' ? 'RM ' : '',
                      suffixText: _discountType == 'percentage' ? '%' : '',
                      prefixStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondaryDark,
                      ),
                      suffixStyle: const TextStyle(
                        fontSize: 20,
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
                          color: AppTheme.accentOrange,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => _calculateDiscount(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Discounts
                  if (_discountType == 'percentage')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [5, 10, 15, 20, 25, 50].map((percent) {
                        return _buildQuickDiscount('$percent%', percent.toDouble());
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // Discount Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentOrange.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Discount Amount',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                            Text(
                              '- RM ${_discountAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Final Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryDark,
                              ),
                            ),
                            Text(
                              'RM ${_finalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.successColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.dividerColor.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyDiscount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Discount',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

  Widget _buildDiscountTypeCard(String type, String label, IconData icon) {
    final isSelected = _discountType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _discountType = type;
          _discountController.clear();
          _discountAmount = 0;
          _finalAmount = widget.currentTotal;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentOrange.withOpacity(0.15)
              : AppTheme.surfaceLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentOrange
                : AppTheme.cardBorderColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppTheme.accentOrange : AppTheme.textSecondaryDark,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.accentOrange : AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDiscount(String label, double value) {
    return InkWell(
      onTap: () {
        setState(() {
          _discountController.text = value.toStringAsFixed(0);
          _calculateDiscount();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}
