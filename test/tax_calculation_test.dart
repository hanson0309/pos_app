import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/models/transaction.dart';

void main() {
  group('Tax Calculation Tests', () {
    test('Tax rate should be stored as percentage (6.0) not decimal (0.06)', () {
      // Arrange
      final item = TransactionItem(
        productId: 'test-product',
        description: 'Test Product',
        quantity: 1,
        unitPrice: 99.98,
        taxType: 'SST',
        taxRate: 6.0, // Should be percentage
        taxAmount: 5.9988, // 99.98 * 6 / 100
        lineTotal: 105.9788,
      );

      // Assert
      expect(item.taxRate, equals(6.0), reason: 'Tax rate should be 6.0 (percentage)');
      expect(item.taxAmount, closeTo(5.9988, 0.0001), reason: 'Tax amount should be ~5.9988');
    });

    test('Tax calculation with percentage format matches backend expectation', () {
      // Arrange
      const unitPrice = 99.98;
      const quantity = 1;
      const taxRate = 6.0; // Percentage format

      // Act - Frontend calculation
      final lineSubtotal = unitPrice * quantity;
      final lineTax = lineSubtotal * (taxRate / 100); // Convert to decimal for calculation

      // Backend calculation (simulated)
      final backendTax = (lineSubtotal * taxRate) / 100;

      // Assert
      expect(lineTax, closeTo(5.9988, 0.0001), reason: 'Frontend tax should be ~5.9988');
      expect(backendTax, closeTo(5.9988, 0.0001), reason: 'Backend tax should be ~5.9988');
      expect(lineTax, equals(backendTax), reason: 'Frontend and backend calculations should match');
    });

    test('Old decimal format (0.06) would produce wrong result', () {
      // Arrange
      const unitPrice = 99.98;
      const oldTaxRate = 0.06; // Old decimal format

      // Act - What backend would calculate with decimal format
      final wrongTax = (unitPrice * oldTaxRate) / 100;

      // Assert
      expect(wrongTax, closeTo(0.059988, 0.000001), reason: 'Decimal format produces wrong result (100x smaller)');
      expect(wrongTax, isNot(closeTo(5.9988, 0.0001)), reason: 'This is NOT the correct tax amount');
    });
  });
}
