import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/cart_item.dart';
import '../repositories/product_repository.dart';

class PosService {
  final AppDatabase database;
  final ProductRepository productRepository;

  PosService(this.database, {ProductRepository? productRepository})
    : productRepository = productRepository ?? ProductRepository(database);

  Future<int> createSale({
    required int boothId,
    required List<CartItem> items,
    required String paymentMethod,
    int discount = 0,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cart cannot be empty.');
    }

    if (discount < 0) {
      throw ArgumentError('Discount cannot be negative.');
    }

    return database.transaction(() async {
      int subtotal = 0;

      final products = <Product, CartItem>{};

      // Validate all products and stock before creating anything.
      for (final item in items) {
        if (item.quantity <= 0) {
          throw ArgumentError('Quantity must be greater than 0.');
        }

        final product = await productRepository.getProduct(
          boothId: boothId,
          productId: item.productId,
        );

        if (product.stockQuantity < item.quantity) {
          throw Exception('Not enough stock for ${product.name}.');
        }

        subtotal += product.price * item.quantity;

        products[product] = item;
      }

      final total = subtotal - discount;

      if (total < 0) {
        throw ArgumentError('Discount cannot be greater than the subtotal.');
      }

      // Create the sale.
      final saleId = await database
          .into(database.sales)
          .insert(
            SalesCompanion.insert(
              boothId: boothId,
              subtotal: subtotal,
              discount: Value(discount),
              total: total,
              paymentMethod: paymentMethod,
              status: 'completed',
              createdAt: DateTime.now(),
            ),
          );

      // Create sale items and update stock.
      for (final entry in products.entries) {
        final product = entry.key;
        final cartItem = entry.value;

        final itemSubtotal = product.price * cartItem.quantity;

        await database
            .into(database.saleItems)
            .insert(
              SaleItemsCompanion.insert(
                saleId: saleId,
                productId: Value(product.id),
                productName: product.name,
                quantity: cartItem.quantity,
                unitPrice: product.price,
                costPrice: Value(product.costPrice),
                subtotal: itemSubtotal,
              ),
            );

        final newStock = product.stockQuantity - cartItem.quantity;

        await productRepository.updateStock(
          productId: product.id,
          newStockQuantity: newStock,
        );

        await database
            .into(database.stockMovements)
            .insert(
              StockMovementsCompanion.insert(
                boothId: boothId,
                productId: product.id,
                movementType: 'sale',
                quantity: -cartItem.quantity,
                referenceType: const Value('sale'),
                referenceId: Value(saleId),
                createdAt: DateTime.now(),
              ),
            );
      }

      return saleId;
    });
  }
}
