import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../models/transaction.dart';
import '../../../config/theme.dart';
import '../providers/cart_provider.dart';
import 'payment_dialog.dart';
import 'item_note_dialog.dart';
import 'discount_dialog.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
      ),
      child: Column(
        children: [
          // Cart Header
          _buildCartHeader(cartItems.length, cartNotifier),

          // Cart Items List
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(cartItems, cartNotifier),
          ),

          // Cart Summary and Checkout
          _buildCartSummary(cartItems, context, ref),
        ],
      ),
    );
  }

  Widget _buildCartHeader(int itemCount, CartNotifier cartNotifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$itemCount items',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (itemCount > 0)
            IconButton(
              onPressed: () => cartNotifier.clear(),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppTheme.textSecondaryDark.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to start a transaction',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(List<CartItem> items, CartNotifier cartNotifier) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCartItem(context, item, cartNotifier);
      },
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartNotifier cartNotifier) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorderColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${item.product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.note_rounded,
                              size: 12,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.note,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => cartNotifier.removeItem(item.product.id!),
                icon: const Icon(Icons.close_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppTheme.textSecondaryDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.cardBorderColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: () => cartNotifier.decrementQuantity(item.product.id!),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add_rounded,
                      onTap: () => cartNotifier.incrementQuantity(item.product.id!),
                    ),
                  ],
                ),
              ),

              // Note Button
              IconButton(
                onPressed: () => _showNoteDialog(context, item, cartNotifier),
                icon: Icon(
                  item.note.isEmpty ? Icons.note_add_rounded : Icons.edit_note_rounded,
                  color: item.note.isEmpty
                      ? AppTheme.textSecondaryDark
                      : AppTheme.primaryColor,
                ),
                tooltip: 'Add Note',
              ),

              // Line Total
              Text(
                'RM ${item.lineTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, CartItem item, CartNotifier cartNotifier) {
    showDialog(
      context: context,
      builder: (context) => ItemNoteDialog(
        currentNote: item.note,
        onSave: (note) {
          cartNotifier.updateNote(item.product.id!, note);
        },
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildCartSummary(List<CartItem> items, BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final subtotal = cartNotifier.subtotal;
    final discount = cartNotifier.discountAmount;
    final discountLabel = cartNotifier.discountLabel;
    final tax = cartNotifier.tax;
    final total = cartNotifier.total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Summary Rows
          _buildSummaryRow('Subtotal', subtotal),

          // Discount Row
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _buildDiscountRow(discount, discountLabel, cartNotifier),
          ],

          const SizedBox(height: 10),
          _buildSummaryRow('Tax (6%)', tax),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.dividerColor.withOpacity(0.3),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: AppTheme.dividerColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: _buildSummaryRow('Total', total, isTotal: true),
          ),

          const SizedBox(height: 20),

          // Discount Button
          if (discount == 0 && items.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDiscountDialog(context, subtotal, ref),
                icon: const Icon(Icons.local_offer_rounded, size: 20),
                label: const Text('Apply Discount'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: AppTheme.accentOrange.withOpacity(0.5),
                  ),
                  foregroundColor: AppTheme.accentOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (discount > 0 || items.isNotEmpty) const SizedBox(height: 12),

          // Payment Buttons
          Row(
            children: [
              Expanded(
                child: _buildPaymentButton(
                  label: 'Cash',
                  icon: Icons.payments_rounded,
                  gradient: AppTheme.successGradient,
                  onTap: items.isEmpty
                      ? null
                      : () => _showPaymentDialog(context, total, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentButton(
                  label: 'Card',
                  icon: Icons.credit_card_rounded,
                  gradient: AppTheme.primaryGradient,
                  onTap: items.isEmpty
                      ? null
                      : () => _showPaymentDialog(context, total, ref),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // More Payment Options
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: items.isEmpty
                  ? null
                  : () {
                      // TODO: Show more payment options
                    },
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              label: const Text(
                'More Options',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: AppTheme.cardBorderColor.withOpacity(0.3),
                ),
                foregroundColor: AppTheme.textPrimaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(double discount, String label, CartNotifier cartNotifier) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 16,
                color: AppTheme.accentOrange,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '- RM ${discount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => cartNotifier.removeDiscount(),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, double subtotal, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
        currentTotal: subtotal,
        onApplyDiscount: (amount, label) {
          ref.read(cartProvider.notifier).applyDiscount(amount, label);
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppTheme.textPrimaryDark : AppTheme.textSecondaryDark,
          ),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 24 : 15,
            fontWeight: FontWeight.w800,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryDark,
            letterSpacing: isTotal ? -0.5 : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isDisabled ? null : gradient,
          color: isDisabled ? AppTheme.surfaceLight.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isDisabled ? AppTheme.textTertiaryDark : Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDisabled ? AppTheme.textTertiaryDark : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, double total, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        totalAmount: total,
        onPaymentComplete: () {
          // Clear cart after successful payment
          ref.read(cartProvider.notifier).clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction completed successfully!'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
