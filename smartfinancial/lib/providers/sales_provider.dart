import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class SalesProvider with ChangeNotifier {
  double _totalSales = 0.0;
  double _totalCost = 0.0;
  double _totalProfit = 0.0;

  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _topSellingProducts = [];

  String? _currentUser;
  String? _token;

  double get totalSales => _totalSales;
  double get totalCost => _totalCost;
  double get totalProfit => _totalProfit;
  List<Map<String, dynamic>> get sales => _sales;
  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get topSellingProducts => _topSellingProducts;

  final AuthService _authService = AuthService();

  Future<void> setUser(String username, String token) async {
    _currentUser = username;
    _token = token;
    await _loadUserData();
    _calculateTotals();
    notifyListeners();
  }

  Future<void> clearUser() async {
    _currentUser = null;
    _token = null;
    _sales.clear();
    _products.clear();
    _topSellingProducts.clear();
    _totalSales = 0.0;
    _totalCost = 0.0;
    _totalProfit = 0.0;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null || _token == null) {
      print('No token or user available');
      return;
    }

    print('Attempting to load data with token: Bearer $_token');
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${_authService.baseUrl}/financial/products/'), headers: {'Authorization': 'Bearer $_token'}),
        http.get(Uri.parse('${_authService.baseUrl}/financial/sales/'), headers: {'Authorization': 'Bearer $_token'}),
        http.get(Uri.parse('${_authService.baseUrl}/financial/top-selling-products/'), headers: {'Authorization': 'Bearer $_token'}),
      ]);

      print('Products response: ${responses[0].statusCode} ${responses[0].body}');
      print('Sales response: ${responses[1].statusCode} ${responses[1].body}');
      print('Top Selling response: ${responses[2].statusCode} ${responses[2].body}');

      _products.clear();
      _sales.clear();
      _topSellingProducts.clear();

      if (responses[0].statusCode == 200) {
        final productsData = jsonDecode(responses[0].body) as List<dynamic>;
        _products.addAll(productsData.map((item) {
          double parseDouble(dynamic value) => value is String ? double.parse(value) : (value as num?)?.toDouble() ?? 0.0;
          int parseInt(dynamic value) => value is String ? int.parse(value) : (value as num?)?.toInt() ?? 0;
          return {
            'id': parseInt(item['id']),
            'name': item['name'] as String? ?? 'Unknown',
            'price': parseDouble(item['price']),
            'cost': parseDouble(item['cost']),
            'stock': parseInt(item['stock']),
          };
        }).toList());
      }
      if (responses[1].statusCode == 200) {
        final salesData = jsonDecode(responses[1].body) as List<dynamic>;
        _sales.addAll(salesData.map((item) {
          double parseDouble(dynamic value) => value is String ? double.parse(value) : (value as num?)?.toDouble() ?? 0.0;
          int parseInt(dynamic value) => value is String ? int.parse(value) : (value as num?)?.toInt() ?? 0;
          return {
            'product': item['product'] as String? ?? 'Unknown',
            'quantity': parseInt(item['quantity']),
            'price': parseDouble(item['price']),
            'cost': parseDouble(item['cost'] ?? 0.0),
            'date': item['date'] as String? ?? DateTime.now().toString().split(' ')[0],
          };
        }).toList());
      }
      if (responses[2].statusCode == 200) {
        final topSellingData = jsonDecode(responses[2].body) as List<dynamic>;
        _topSellingProducts.addAll(topSellingData.map((item) {
          int parseInt(dynamic value) => value is String ? int.parse(value) : (value as num?)?.toInt() ?? 0;
          return {
            'name': item['name'] as String? ?? 'Unknown',
            'quantity': parseInt(item['quantity']),
          };
        }).toList());
      }
      _calculateTotals();
      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
    }
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

  Future<void> addSale(Map<String, dynamic> sale) async {
    try {
      if (_token == null) throw Exception('No authentication token');

      print('Attempting to add sale: $sale');
      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/financial/sales/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(sale),
      );

      print('Add Sale response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        await _loadUserData();
        _calculateTotals();
        notifyListeners();
      } else if (response.statusCode == 401) {
        print('Token expired, please log in again.');
        throw Exception('Authentication failed: Token expired. Please log in again.');
      } else {
        throw Exception('Failed to add sale: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding sale: $e');
      throw Exception('Failed to add sale: ${e.toString()}');
    }
  }

  Future<void> addProduct(String name, double price, double cost, int stock) async {
    if (_products.any((p) => p['name'].toLowerCase() == name.toLowerCase())) {
      throw Exception('Product "$name" already exists');
    }
    try {
      if (_token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/financial/products/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'price': price, 'cost': cost, 'stock': stock}),
      );

      if (response.statusCode == 201) {
        await _loadUserData();
        notifyListeners();
      } else {
        throw Exception('Failed to add product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add product: ${e.toString()}');
    }
  }

  Future<void> deleteProduct(String name) async {
    try {
      if (_token == null) throw Exception('No authentication token');

      final product = _products.firstWhere((p) => p['name'] == name);
      final response = await http.delete(
        Uri.parse('${_authService.baseUrl}/financial/products/${product['id']}/'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 204) {
        await _loadUserData();
        _calculateTotals();
        notifyListeners();
      } else {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }
}