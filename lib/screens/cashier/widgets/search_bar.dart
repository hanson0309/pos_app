import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class CashierSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;

  const CashierSearchBar({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<CashierSearchBar> createState() => _CashierSearchBarState();
}

class _CashierSearchBarState extends State<CashierSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cardBorderColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearchChanged,
        style: const TextStyle(
          fontSize: 15,
          color: AppTheme.textPrimaryDark,
        ),
        decoration: InputDecoration(
          hintText: 'Search products by name or barcode...',
          hintStyle: TextStyle(
            color: AppTheme.textSecondaryDark.withOpacity(0.6),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondaryDark,
            size: 24,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppTheme.textSecondaryDark,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
