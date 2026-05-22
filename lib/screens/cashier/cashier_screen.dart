import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../config/theme.dart';
import '../../services/product_sync_service.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_panel.dart';
import 'widgets/category_tabs.dart';
import 'widgets/search_bar.dart';

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSyncing = false;
  bool _isCartExpanded = true;

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = ProductSyncService();
      await syncService.incrementalSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh the product grid
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Row(
          children: [
            // Left Side - Product Selection Area (70%)
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  // Top Bar with Search and Quick Actions
                  _buildTopBar(),

                  // Category Tabs
                  CategoryTabs(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),

                  // Product Grid
                  Expanded(
                    child: ProductGrid(
                      category: _selectedCategory,
                      searchQuery: _searchQuery,
                    ),
                  ),
                ],
              ),
            ),

            // Vertical Divider
            Container(
              width: 1,
              color: AppTheme.dividerColor.withOpacity(0.3),
            ),

            // Right Side - Cart and Checkout Area (collapsible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _isCartExpanded ? 420 : 60,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: Stack(
                children: [
                  if (_isCartExpanded)
                    const CartPanel(),
                  if (!_isCartExpanded)
                    Container(
                      color: AppTheme.surfaceDark,
                      width: 60,
                    ),
                  // Toggle button
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCartExpanded = !_isCartExpanded;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(2, 0),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isCartExpanded
                                ? Icons.chevron_right_rounded
                                : Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo/Store Name with Gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'POS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Search Bar
          Expanded(
            child: CashierSearchBar(
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),

          const SizedBox(width: 16),

          // Quick Action Buttons - Wrapped to prevent overflow
          Flexible(
            child: Wrap(
              spacing: 8,
              children: [
                _buildQuickActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan',
                  onTap: () {
                    // TODO: Implement barcode scanner
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'Customer',
                  onTap: () {
                    // TODO: Implement customer selection
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () {
                    // TODO: Implement transaction history
                  },
                ),
                _buildQuickActionButton(
                  icon: _isSyncing ? Icons.sync_disabled : Icons.sync_rounded,
                  label: 'Sync',
                  onTap: _isSyncing ? () {} : _syncData,
                  isLoading: _isSyncing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimaryDark),
                ),
              )
            else
              Icon(icon, size: 18, color: AppTheme.textPrimaryDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
