import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key, required this.onSaleRecorded});

  final VoidCallback onSaleRecorded;

  @override
  _AddSaleScreenState createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != _selectedDate && mounted) {
        setState(() => _selectedDate = picked);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error selecting date: ${e.toString()}');
      }
    }
  }

  Future<void> _addSale() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quantityText = _quantityController.text.trim();
      final quantity = int.tryParse(quantityText);

      if (_selectedProduct == null) {
        throw Exception('Please select a product.');
      }
      if (quantity == null || quantity <= 0) {
        throw Exception('Please enter a valid quantity greater than 0.');
      }

      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final product = salesProvider.products.firstWhere(
            (p) => p['name'] == _selectedProduct,
        orElse: () => throw Exception('Selected product not found in inventory.'),
      );

      await Future.microtask(() {
        salesProvider.addSale({
          'product': product['id'],
          'quantity': quantity,
          'price': (product['price'] as num?)?.toDouble() ?? 0.0,
          'cost': (product['cost'] as num?)?.toDouble() ?? 0.0,
          'date': _selectedDate.toString().split(' ')[0],
        });
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedProduct = null;
          _quantityController.clear();
          _selectedDate = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded successfully')),
        );
        widget.onSaleRecorded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error recording sale: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    print('Products in AddSaleScreen: ${salesProvider.products}');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text(
                      'Add Sale',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Sale',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          if (salesProvider.products.isEmpty)
                            const Text(
                              'No products available. Please add a product in the Inventory screen first.',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _selectedProduct,
                              decoration: InputDecoration(
                                labelText: 'Product',
                                prefixIcon: const Icon(Icons.production_quantity_limits, color: Colors.grey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              items: salesProvider.products.map((product) {
                                final stock = (product['stock'] as num?)?.toInt() ?? 0;
                                return DropdownMenuItem<String>(
                                  value: product['name'],
                                  child: Text('${product['name'] ?? 'Unknown'} (Stock: $stock)'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {
                                    _selectedProduct = value;
                                    _errorMessage = null;
                                  });
                                }
                              },
                              hint: const Text('Select a product'),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: const Icon(Icons.numbers, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            onChanged: (value) {
                              if (mounted) {
                                setState(() => _errorMessage = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Date: ${_selectedDate.toString().split(' ')[0]}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : () => _selectDate(context),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(color: Color(0xFF26A69A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          ElevatedButton(
                            onPressed: (salesProvider.products.isEmpty || _isLoading) ? null : _addSale,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26A69A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Text('Record Sale', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}