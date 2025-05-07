// lib/screens/admin/product_management_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _managerDiscountController = TextEditingController();
  final TextEditingController _salesmanDiscountController = TextEditingController();

  File? _selectedImage;

  // Sets to store existing categories and subcategories
  Set<String> _existingCategories = {};
  Set<String> _existingSubcategories = {};

  @override
  void initState() {
    super.initState();
    _fetchExistingCategoriesAndSubcategories();
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
    // Removed unused 'productService' variable
    return Scaffold(
      appBar: AppBar(title: const Text('Product Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Import CSV Button
            ElevatedButton.icon(
              onPressed: _importCsv,
              icon: const Icon(Icons.file_upload),
              label: const Text('Import Products from CSV'),
            ),
            const SizedBox(height: 20),
            // Add Product Button
            ElevatedButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Product Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final csvContent = await file.readAsString();
        final rows = const LineSplitter().convert(csvContent);

        final productService = Provider.of<ProductService>(context, listen: false);

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
            await productService.updateProduct(existingProduct.id, updatedData, null);
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
          SnackBar(content: Text('Products imported successfully. $addedCount added, $updatedCount updated.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import products: $e')),
      );
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
        return AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildAutocompleteField(
                  controller: _categoryController,
                  label: 'Category',
                  options: _existingCategories.toList(),
                ),
                _buildAutocompleteField(
                  controller: _subcategoryController,
                  label: 'Subcategory',
                  options: _existingSubcategories.toList(),
                ),
                _buildTextField(_itemNameController, 'Item Name'),
                _buildTextField(_codeController, 'Code'),
                _buildTextField(_mrpController, 'MRP', isNumber: true),
                _buildTextField(_taxController, 'Tax (%)', isNumber: true),
                _buildTextField(_managerDiscountController, 'Manager Discount (%)', isNumber: true),
                _buildTextField(_salesmanDiscountController, 'Salesman Discount (%)', isNumber: true),
                const SizedBox(height: 10),
                _buildImagePicker(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProduct() async {
    final product = ProductModel(
      id: '',
      category: _categoryController.text.trim(),
      subcategory: _subcategoryController.text.trim(),
      itemName: _itemNameController.text.trim(),
      code: _codeController.text.trim(),
      mrp: double.tryParse(_mrpController.text.trim()) ?? 0.0,
      tax: double.tryParse(_taxController.text.trim()) ?? 0.0,
      managerDiscount: double.tryParse(_managerDiscountController.text.trim()) ?? 0.0,
      salesmanDiscount: double.tryParse(_salesmanDiscountController.text.trim()) ?? 0.0,
      imageUrl: '',
    );

    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      await productService.addProduct(product, _selectedImage);

      // Refresh existing categories and subcategories
      _fetchExistingCategoriesAndSubcategories();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );

      _clearControllers();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    }
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setState(() {
                _selectedImage = File(pickedFile.path);
              });
            }
          },
          icon: const Icon(Icons.image),
          label: const Text('Select Image'),
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Image.file(_selectedImage!, width: 100, height: 100, fit: BoxFit.cover),
          ),
      ],
    );
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

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          } else {
            return options.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          }
        },
        onSelected: (String selection) {
          controller.text = selection;
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(labelText: label),
          );
        },
      ),
    );
  }
}
