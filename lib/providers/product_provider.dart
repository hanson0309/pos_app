import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_sync_service.dart';

// Product sync service provider
final productSyncServiceProvider = Provider<ProductSyncService>((ref) {
  return ProductSyncService();
});

// Products list provider
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final syncService = ref.watch(productSyncServiceProvider);
  return await syncService.getLocalProducts();
});

// Filtered products provider (with search)
final filteredProductsProvider = FutureProvider.family<List<Product>, String>((ref, searchQuery) async {
  final syncService = ref.watch(productSyncServiceProvider);
  return await syncService.getLocalProducts(search: searchQuery.isEmpty ? null : searchQuery);
});

// Product by barcode provider
final productByBarcodeProvider = FutureProvider.family<Product?, String>((ref, barcode) async {
  final syncService = ref.watch(productSyncServiceProvider);
  return await syncService.findByBarcode(barcode);
});
