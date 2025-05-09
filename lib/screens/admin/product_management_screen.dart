// lib/screens/admin/product_management_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'product_list_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with TickerProviderStateMixin {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _managerDiscountController =
      TextEditingController();
  final TextEditingController _salesmanDiscountController =
      TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sets to store existing categories and subcategories
  Set<String> _existingCategories = {};
  Set<String> _existingSubcategories = {};

  @override
  void initState() {
    super.initState();
    _fetchExistingCategoriesAndSubcategories();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _subcategoryController.dispose();
    _itemNameController.dispose();
    _codeController.dispose();
    _mrpController.dispose();
    _taxController.dispose();
    _managerDiscountController.dispose();
    _salesmanDiscountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _fetchExistingCategoriesAndSubcategories() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    final products = await productService.getAllProductsOnce();
    setState(() {
      _existingCategories = products.map((e) => e.category).toSet();
      _existingSubcategories = products.map((e) => e.subcategory).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
              title: Text(
                'Product Management',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductListScreen()),
          );
        },
        backgroundColor: Colors.indigo.shade700,
        child: const Icon(Icons.view_list, color: Colors.white),
        tooltip: 'View Products',
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFeatureCard(
                title: 'Import Products',
                subtitle: 'Add multiple products from a CSV file',
                icon: Icons.upload_file,
                color: Colors.deepPurple,
                onTap: _importCsv,
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(
                title: 'Add Product Manually',
                subtitle: 'Create a new product with details',
                icon: Icons.add_circle,
                color: Colors.indigo,
                onTap: _showAddProductDialog,
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(
                title: 'Browse Products',
                subtitle: 'View and manage your product catalog',
                icon: Icons.inventory_2,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProductListScreen()),
                  );
                },
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.indigo.shade600),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importCsv() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final csvContent = await file.readAsString();
        final rows = const LineSplitter().convert(csvContent);

        final productService =
            Provider.of<ProductService>(context, listen: false);

        int addedCount = 0;
        int updatedCount = 0;

        for (int i = 1; i < rows.length; i++) {
          final fields = _parseCsvRow(rows[i]);
          if (fields.length < 9) continue;

          String category = fields[0];
          String subcategory = fields[1];
          String itemName = fields[2];
          String code = fields[3];
          double mrp = double.tryParse(fields[4]) ?? 0.0;
          double tax = double.tryParse(fields[5]) ?? 0.0;
          String imageUrl = fields[6];
          double managerDiscount = double.tryParse(fields[7]) ?? 0.0;
          double salesmanDiscount = double.tryParse(fields[8]) ?? 0.0;

          var existingProduct = await productService.getProductByCode(code);

          if (existingProduct != null) {
            // Update existing product
            Map<String, dynamic> updatedData = {
              'category': category,
              'subcategory': subcategory,
              'itemName': itemName,
              'mrp': mrp,
              'tax': tax,
              'imageUrl': imageUrl,
              'managerDiscount': managerDiscount,
              'salesmanDiscount': salesmanDiscount,
            };
            await productService.updateProduct(
                existingProduct.id, updatedData, null);
            updatedCount++;
          } else {
            // Add new product
            ProductModel newProduct = ProductModel(
              id: '',
              category: category,
              subcategory: subcategory,
              itemName: itemName,
              code: code,
              mrp: mrp,
              tax: tax,
              imageUrl: imageUrl,
              managerDiscount: managerDiscount,
              salesmanDiscount: salesmanDiscount,
            );
            await productService.addProduct(newProduct, null);
            addedCount++;
          }
        }

        // Refresh existing categories and subcategories
        _fetchExistingCategoriesAndSubcategories();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Products imported successfully. $addedCount added, $updatedCount updated.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to import products: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _parseCsvRow(String row) {
    // Handle commas inside quotes
    List<String> fields = [];
    bool inQuotes = false;
    StringBuffer field = StringBuffer();

    for (int i = 0; i < row.length; i++) {
      if (row[i] == '"') {
        inQuotes = !inQuotes;
      } else if (row[i] == ',' && !inQuotes) {
        fields.add(field.toString());
        field.clear();
      } else {
        field.write(row[i]);
      }
    }
    fields.add(field.toString());
    return fields.map((f) => f.trim().replaceAll('"', '')).toList();
  }

  void _showAddProductDialog() {
    _clearControllers();
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: FadeIn(
              duration: const Duration(milliseconds: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Product',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: _selectedImage != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.add_a_photo,
                                            size: 40,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade600,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Category and Subcategory
                          Row(
                            children: [
                              Expanded(
                                child: _buildAutocompleteField(
                                  controller: _categoryController,
                                  label: 'Category',
                                  options: _existingCategories.toList(),
                                  icon: Icons.category,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAutocompleteField(
                                  controller: _subcategoryController,
                                  label: 'Subcategory',
                                  options: _existingSubcategories.toList(),
                                  icon: Icons.segment,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Product Name and Code
                          _buildTextField(_itemNameController, 'Item Name',
                              Icons.inventory_2),
                          const SizedBox(height: 16),
                          _buildTextField(
                              _codeController, 'Product Code', Icons.qr_code),
                          const SizedBox(height: 16),
                          // MRP and Tax
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(_mrpController,
                                    'MRP (₹)', Icons.currency_rupee,
                                    isNumber: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                    _taxController, 'Tax (%)', Icons.receipt,
                                    isNumber: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Discounts
                          Text(
                            'Discount Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    _managerDiscountController,
                                    'Manager (%)',
                                    Icons.person,
                                    isNumber: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                    _salesmanDiscountController,
                                    'Salesman (%)',
                                    Icons.support_agent,
                                    isNumber: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Add Product',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
        prefixIcon: Icon(icon, color: Colors.indigo.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    required IconData icon,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return options.where((option) =>
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        // Sync the autocomplete controller with our controller
        textEditingController.text = controller.text;
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) {
            controller.text = value;
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            prefixIcon: Icon(icon, color: Colors.indigo.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 200,
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _clearControllers() {
    _categoryController.clear();
    _subcategoryController.clear();
    _itemNameController.clear();
    _codeController.clear();
    _mrpController.clear();
    _taxController.clear();
    _managerDiscountController.clear();
    _salesmanDiscountController.clear();
  }

  Future<void> _addProduct() async {
    if (_itemNameController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty ||
        _mrpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all mandatory fields (Item Name, Code, MRP)',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productService =
          Provider.of<ProductService>(context, listen: false);

      // Check if product code already exists
      final existingProduct =
          await productService.getProductByCode(_codeController.text.trim());
      if (existingProduct != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A product with this code already exists',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final newProduct = ProductModel(
        id: '',
        category: _categoryController.text.trim(),
        subcategory: _subcategoryController.text.trim(),
        itemName: _itemNameController.text.trim(),
        code: _codeController.text.trim(),
        mrp: double.tryParse(_mrpController.text.trim()) ?? 0.0,
        tax: double.tryParse(_taxController.text.trim()) ?? 0.0,
        imageUrl: '',
        managerDiscount:
            double.tryParse(_managerDiscountController.text.trim()) ?? 0.0,
        salesmanDiscount:
            double.tryParse(_salesmanDiscountController.text.trim()) ?? 0.0,
      );

      await productService.addProduct(newProduct, _selectedImage);

      // Update category and subcategory collections
      _fetchExistingCategoriesAndSubcategories();

      _clearControllers();
      _selectedImage = null;

      // Close the dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product added successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error adding product: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
