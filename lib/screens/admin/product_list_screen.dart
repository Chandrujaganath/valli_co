// lib/screens/admin/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../screens/admin/product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with TickerProviderStateMixin {
  String selectedCategory = 'All';
  String selectedSubcategory = 'All';
  String sortBy = 'Name'; // Options: Name, MRP, Code
  bool isGridView = true; // Toggle between grid and list view

  List<String> availableCategories = [];
  List<String> availableSubcategories = [];
  List<ProductModel> allProducts = [];
  List<ProductModel> filteredProducts = [];
  bool isLoading = true;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    // Setup animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _fetchProducts() {
    setState(() {
      isLoading = true;
    });

    final productService = Provider.of<ProductService>(context, listen: false);
    productService.getProductsStream().listen((products) {
      setState(() {
        allProducts = products;
        _initializeCategories();
        _applyFilters();
        isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $error')),
      );
    });
  }

  void _initializeCategories() {
    availableCategories = [
      'All',
      ...allProducts.map((e) => e.category).toSet()
    ];
    _updateSubcategories();
  }

  void _updateSubcategories() {
    if (selectedCategory == 'All') {
      availableSubcategories = [
        'All',
        ...allProducts.map((e) => e.subcategory).toSet()
      ];
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
      filtered =
          filtered.where((e) => e.subcategory == selectedSubcategory).toList();
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade800,
                Colors.indigo.shade500,
              ],
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          'Product Catalog',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          // Toggle view
          IconButton(
            icon: Icon(
              isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
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
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
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
            icon: const Icon(Icons.sort, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Selection
          FadeIn(
            duration: const Duration(milliseconds: 600),
            child: _buildCategoryChips(),
          ),
          // Subcategory Selection
          FadeIn(
            duration: const Duration(milliseconds: 800),
            child: _buildSubcategoryChips(),
          ),
          // Product List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 70, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: isGridView
                            ? _buildProductGrid()
                            : _buildProductList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availableCategories.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selectedCategory == category
                        ? Colors.white
                        : Colors.grey.shade800,
                  ),
                ),
                selected: selectedCategory == category,
                selectedColor: Colors.indigo.shade500,
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
      ),
    );
  }

  Widget _buildSubcategoryChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availableSubcategories.map((subcategory) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  subcategory,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selectedSubcategory == subcategory
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
                selected: selectedSubcategory == subcategory,
                selectedColor: Colors.indigo.shade400,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductGridItem(filteredProducts[index], index);
      },
    );
  }

  Widget _buildProductGridItem(ProductModel product, int index) {
    return FadeInUp(
      delay: Duration(milliseconds: 50 * (index % 4)),
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? Hero(
                            tag: 'product-${product.id}',
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported,
                                    size: 60, color: Colors.grey);
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.indigo.shade300),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.inventory_2,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
              ),
              // Product Info
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${product.code}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${product.mrp.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${product.tax}%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.indigo.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(filteredProducts[index], index);
      },
    );
  }

  Widget _buildProductCard(ProductModel product, int index) {
    return FadeInLeft(
      delay: Duration(milliseconds: 50 * (index % 5)),
      duration: const Duration(milliseconds: 400),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: product.imageUrl.isNotEmpty
                        ? Hero(
                            tag: 'product-${product.id}',
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported,
                                    size: 40, color: Colors.grey);
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            ),
                          )
                        : Icon(Icons.inventory_2,
                            size: 40, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 16),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.itemName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${product.category} > ${product.subcategory}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Code: ${product.code}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${product.mrp.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Search delegate for products
class ProductSearchDelegate extends SearchDelegate<ProductModel> {
  final List<ProductModel> products;
  final Function(ProductModel) onSelected;

  ProductSearchDelegate({required this.products, required this.onSelected});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, products.first);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredProducts = products.where((product) {
      return product.itemName.toLowerCase().contains(query.toLowerCase()) ||
          product.code.toLowerCase().contains(query.toLowerCase()) ||
          product.category.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Container(
      color: Colors.grey.shade50,
      child: filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No matching products found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: product.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Icon(Icons.inventory_2,
                                color: Colors.grey.shade500),
                      ),
                      title: Text(
                        product.itemName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Code: ${product.code} • ₹${product.mrp.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      onTap: () {
                        close(context, product);
                        onSelected(product);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
