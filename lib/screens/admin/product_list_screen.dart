// lib/screens/admin/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../screens/admin/product_details_screen.dart'; // Ensure correct import path

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String selectedCategory = 'All';
  String selectedSubcategory = 'All';
  String sortBy = 'Name'; // Options: Name, MRP, Code

  List<String> availableCategories = [];
  List<String> availableSubcategories = [];
  List<ProductModel> allProducts = [];
  List<ProductModel> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() {
    final productService = Provider.of<ProductService>(context, listen: false);
    productService.getProductsStream().listen((products) {
      setState(() {
        allProducts = products;
        _initializeCategories();
        _applyFilters();
      });
    }, onError: (error) {
      // Handle error if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $error')),
      );
    });
  }

  void _initializeCategories() {
    availableCategories = ['All', ...allProducts.map((e) => e.category).toSet()];
    _updateSubcategories();
  }

  void _updateSubcategories() {
    if (selectedCategory == 'All') {
      availableSubcategories = ['All', ...allProducts.map((e) => e.subcategory).toSet()];
    } else {
      availableSubcategories = [
        'All',
        ...allProducts
            .where((e) => e.category == selectedCategory)
            .map((e) => e.subcategory)
            .toSet()
      ];
    }
  }

  void _applyFilters() {
    var filtered = allProducts;

    if (selectedCategory != 'All') {
      filtered = filtered.where((e) => e.category == selectedCategory).toList();
    }
    if (selectedSubcategory != 'All') {
      filtered = filtered.where((e) => e.subcategory == selectedSubcategory).toList();
    }

    switch (sortBy) {
      case 'Name':
        filtered.sort((a, b) => a.itemName.compareTo(b.itemName));
        break;
      case 'MRP':
        filtered.sort((a, b) => a.mrp.compareTo(b.mrp));
        break;
      case 'Code':
        filtered.sort((a, b) => a.code.compareTo(b.code));
        break;
    }

    setState(() {
      filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        actions: [
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(
                  products: allProducts,
                  onSelected: (product) {
                    // Navigate to product details when a product is selected from search
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Sort Options
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortBy = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'MRP',
                child: Text('Sort by MRP'),
              ),
              const PopupMenuItem(
                value: 'Code',
                child: Text('Sort by Code'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Selection
          _buildCategoryChips(),
          // Subcategory Selection
          _buildSubcategoryChips(),
          // Product List
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('No products found.'))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: availableCategories.map((category) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category, style: const TextStyle(fontSize: 14)),
              selected: selectedCategory == category,
              onSelected: (bool selected) {
                setState(() {
                  selectedCategory = category;
                  selectedSubcategory = 'All';
                  _updateSubcategories();
                  _applyFilters();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubcategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: availableSubcategories.map((subcategory) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(subcategory, style: const TextStyle(fontSize: 14)),
              selected: selectedSubcategory == subcategory,
              onSelected: (bool selected) {
                setState(() {
                  selectedSubcategory = subcategory;
                  _applyFilters();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        leading: product.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 50);
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              )
            : const Icon(Icons.image_not_supported, size: 50),
        title: Text(
          product.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Code: ${product.code}\nMRP: ₹${product.mrp.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14),
        ),
        isThreeLine: true,
        onTap: () {
          // Navigate to the product details screen when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
      ),
    );
  }
}

// Search Delegate for handling product search
class ProductSearchDelegate extends SearchDelegate<ProductModel?> {
  final List<ProductModel> products;
  final Function(ProductModel) onSelected;

  ProductSearchDelegate({required this.products, required this.onSelected});

  @override
  String get searchFieldLabel => 'Search Products';

  @override
  TextStyle get searchFieldStyle => const TextStyle(fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = products.where((product) {
      final lowerQuery = query.toLowerCase();
      return product.itemName.toLowerCase().contains(lowerQuery) ||
          product.code.toLowerCase().contains(lowerQuery);
    }).toList();

    return _buildProductList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products.where((product) {
      final lowerQuery = query.toLowerCase();
      return product.itemName.toLowerCase().contains(lowerQuery) ||
          product.code.toLowerCase().contains(lowerQuery);
    }).toList();

    return _buildProductList(suggestions);
  }

  Widget _buildProductList(List<ProductModel> productList) {
    if (productList.isEmpty) {
      return const Center(child: Text('No products found.'));
    }
    return ListView.builder(
      itemCount: productList.length,
      itemBuilder: (context, index) {
        final product = productList[index];
        return ListTile(
          leading: product.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported);
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                )
              : const Icon(Icons.image_not_supported),
          title: Text(product.itemName),
          subtitle: Text('Code: ${product.code}'),
          onTap: () {
            onSelected(product);
            close(context, product);
          },
        );
      },
    );
  }
}
