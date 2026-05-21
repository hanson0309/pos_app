import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';

// Cart Item Model
class CartItem {
  final Product product;
  final int quantity;
  final String note;

  CartItem({
    required this.product,
    required this.quantity,
    this.note = '',
  });

  double get lineTotal => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? note,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}

// Cart State Notifier
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  double _discountAmount = 0;
  String _discountLabel = '';

  double get discountAmount => _discountAmount;
  String get discountLabel => _discountLabel;

  void addItem(Product product) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Product already in cart, increment quantity
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      // Add new product to cart
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void incrementQuantity(String productId) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: item.quantity + 1)
        else
          item,
    ];
  }

  void decrementQuantity(String productId) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          if (item.quantity > 1)
            item.copyWith(quantity: item.quantity - 1)
          else
            item // Keep at 1, don't go below
        else
          item,
    ];
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  void updateNote(String productId, String note) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(note: note)
        else
          item,
    ];
  }

  void applyDiscount(double amount, String label) {
    _discountAmount = amount;
    _discountLabel = label;
    // Trigger rebuild
    state = [...state];
  }

  void removeDiscount() {
    _discountAmount = 0;
    _discountLabel = '';
    // Trigger rebuild
    state = [...state];
  }

  void clear() {
    state = [];
    _discountAmount = 0;
    _discountLabel = '';
  }

  double get subtotal {
    return state.fold(0, (sum, item) => sum + item.lineTotal);
  }

  double get tax {
    return (subtotal - _discountAmount) * 0.06; // 6% SST after discount
  }

  double get total {
    return subtotal - _discountAmount + tax;
  }

  int get itemCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

// Cart Provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
