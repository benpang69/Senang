import 'package:drift/drift.dart';

import '../database/database.dart';

class ProductRepository {
  final AppDatabase database;

  ProductRepository(this.database);

  Future<List<Product>> getProductsByBooth(int boothId) {
    return (database.select(database.products)
          ..where((tbl) => tbl.boothId.equals(boothId))
          ..where((tbl) => tbl.isActive.equals(true)))
        .get();
  }

  Future<Product> getProduct({required int boothId, required int productId}) {
    return (database.select(database.products)
          ..where((tbl) => tbl.id.equals(productId))
          ..where((tbl) => tbl.boothId.equals(boothId)))
        .getSingle();
  }

  Future<int> createProduct({
    required int boothId,
    required String name,
    required int price,
    int? categoryId,
    String? sku,
    String? description,
    int? costPrice,
    int stockQuantity = 0,
    int lowStockThreshold = 0,
  }) {
    return database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            categoryId: Value<int?>(categoryId),
            name: name,
            sku: Value<String?>(sku),
            description: Value<String?>(description),
            price: price,
            costPrice: Value<int?>(costPrice),
            stockQuantity: Value(stockQuantity),
            lowStockThreshold: Value(lowStockThreshold),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<int> updateProduct({
    required int productId,
    required String name,
    required int price,
    int? categoryId,
    String? sku,
    String? description,
    int? costPrice,
    int lowStockThreshold = 0,
  }) {
    return (database.update(
      database.products,
    )..where((tbl) => tbl.id.equals(productId))).write(
      ProductsCompanion(
        name: Value(name),
        price: Value(price),
        categoryId: Value<int?>(categoryId),
        sku: Value<String?>(sku),
        description: Value<String?>(description),
        costPrice: Value<int?>(costPrice),
        lowStockThreshold: Value(lowStockThreshold),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateStock({
    required int productId,
    required int newStockQuantity,
  }) {
    return (database.update(
      database.products,
    )..where((tbl) => tbl.id.equals(productId))).write(
      ProductsCompanion(
        stockQuantity: Value(newStockQuantity),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deactivateProduct(int productId) {
    return (database.update(
      database.products,
    )..where((tbl) => tbl.id.equals(productId))).write(
      ProductsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
