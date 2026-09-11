import 'package:drift/drift.dart';

import '../database/database.dart';
import '../repositories/product_repository.dart';

class InventoryService {
  final AppDatabase database;
  final ProductRepository productRepository;

  InventoryService(this.database, {ProductRepository? productRepository})
    : productRepository = productRepository ?? ProductRepository(database);

  Future<int> addStock({
    required int boothId,
    required int productId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0.');
    }

    return database.transaction(() async {
      final product = await productRepository.getProduct(
        boothId: boothId,
        productId: productId,
      );

      final newStock = product.stockQuantity + quantity;

      await productRepository.updateStock(
        productId: productId,
        newStockQuantity: newStock,
      );

      await database
          .into(database.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              boothId: boothId,
              productId: productId,
              movementType: 'restock',
              quantity: quantity,
              note: Value(note),
              createdAt: DateTime.now(),
            ),
          );

      return newStock;
    });
  }

  Future<int> removeStock({
    required int boothId,
    required int productId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0.');
    }

    return database.transaction(() async {
      final product = await productRepository.getProduct(
        boothId: boothId,
        productId: productId,
      );

      if (quantity > product.stockQuantity) {
        throw Exception('Cannot remove more stock than currently available.');
      }

      final newStock = product.stockQuantity - quantity;

      await productRepository.updateStock(
        productId: productId,
        newStockQuantity: newStock,
      );

      await database
          .into(database.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              boothId: boothId,
              productId: productId,
              movementType: 'adjustment',
              quantity: -quantity,
              note: Value(note),
              createdAt: DateTime.now(),
            ),
          );

      return newStock;
    });
  }

  Future<List<Product>> getLowStockProducts(int boothId) async {
    final products = await productRepository.getProductsByBooth(boothId);

    return products
        .where((product) => product.stockQuantity <= product.lowStockThreshold)
        .toList();
  }
}
