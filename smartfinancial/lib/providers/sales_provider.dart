import 'package:flutter/foundation.dart';

class SalesProvider with ChangeNotifier {
  double _totalSales = 0.0;
  double _totalCost = 0.0;
  double _totalProfit = 0.0;

  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _topSellingProducts = [];

  double get totalSales => _totalSales;
  double get totalCost => _totalCost;
  double get totalProfit => _totalProfit;
  List<Map<String, dynamic>> get sales => _sales;
  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get topSellingProducts => _topSellingProducts;

  SalesProvider() {
    _calculateTotals();
  }

  void _calculateTotals() {
    _totalSales = _sales.fold(0.0, (sum, sale) {
      final quantity = (sale['quantity'] as num).toDouble();
      final price = (sale['price'] as num).toDouble();
      return sum + (quantity * price);
    });
    _totalCost = _sales.fold(0.0, (sum, sale) {
      final quantity = (sale['quantity'] as num).toDouble();
      final cost = (sale['cost'] as num).toDouble();
      return sum + (quantity * cost);
    });
    _totalProfit = _totalSales - _totalCost;
  }

  void addSale(Map<String, dynamic> sale) {
    try {
      final productName = sale['product'] as String?;
      final quantity = sale['quantity'] as int?;
      final price = sale['price'] as double?;
      final date = sale['date'] as String?;

      if (productName == null || quantity == null || price == null || date == null) {
        throw Exception('Invalid sale data provided.');
      }

      final product = _products.firstWhere(
            (p) => p['name'] == productName,
        orElse: () => throw Exception('Product $productName not found in inventory.'),
      );

      if (product['stock'] < quantity) {
        throw Exception('Insufficient stock for $productName. Available: ${product['stock']}');
      }

      product['stock'] -= quantity;
      final newSale = {
        'id': _sales.isNotEmpty ? (_sales.last['id'] as int) + 1 : 1,
        'product': productName,
        'quantity': quantity,
        'price': price,
        'cost': product['cost'] as double,
        'date': date,
      };
      _sales.insert(0, newSale);
      _calculateTotals();

      final topProductIndex = _topSellingProducts.indexWhere((p) => p['name'] == productName);
      if (topProductIndex != -1) {
        _topSellingProducts[topProductIndex]['quantity'] = (_topSellingProducts[topProductIndex]['quantity'] as int) + quantity;
      } else {
        _topSellingProducts.add({'name': productName, 'quantity': quantity});
      }
      _topSellingProducts.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add sale: ${e.toString()}');
    }
  }

  void addProduct(String name, double price, double cost, int stock) {
    if (_products.any((p) => p['name'].toLowerCase() == name.toLowerCase())) {
      throw Exception('Product "$name" already exists');
    }
    _products.add({
      'name': name,
      'stock': stock,
      'price': price,
      'cost': cost,
    });
    notifyListeners();
  }

  void deleteProduct(String name) {
    _products.removeWhere((p) => p['name'] == name);
    _sales.removeWhere((s) => s['product'] == name);
    _topSellingProducts.removeWhere((t) => t['name'] == name);
    _calculateTotals();
    notifyListeners();
  }
}