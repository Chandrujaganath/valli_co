// lib/screens/admin/product_details_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart'; // Ensure UserRoles is defined here

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool isEditing = false;
  bool _isLoading = false;
  File? _selectedImage;

  // Controllers for editing fields
  late TextEditingController _categoryController;
  late TextEditingController _subcategoryController;
  late TextEditingController _itemNameController;
  late TextEditingController _codeController;
  late TextEditingController _mrpController;
  late TextEditingController _taxController;
  late TextEditingController _managerDiscountController;
  late TextEditingController _salesmanDiscountController;

  @override
  void initState() {
    super.initState();
    _categoryController =
        TextEditingController(text: widget.product.category);
    _subcategoryController =
        TextEditingController(text: widget.product.subcategory);
    _itemNameController =
        TextEditingController(text: widget.product.itemName);
    _codeController = TextEditingController(text: widget.product.code);
    _mrpController = TextEditingController(text: widget.product.mrp.toString());
    _taxController = TextEditingController(text: widget.product.tax.toString());
    _managerDiscountController = TextEditingController(
        text: widget.product.managerDiscount.toString());
    _salesmanDiscountController = TextEditingController(
        text: widget.product.salesmanDiscount.toString());
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

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${widget.product.itemName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      setState(() {
        _isLoading = true;
      });
      final productService =
          Provider.of<ProductService>(context, listen: false);
      await productService.deleteProduct(
          widget.product.id, widget.product.imageUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveEdits() async {
    if (_itemNameController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty ||
        _mrpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory fields.')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Changes'),
        content: const Text('Are you sure you want to save the changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      setState(() {
        _isLoading = true;
      });
      final updatedProduct = ProductModel(
        id: widget.product.id,
        category: _categoryController.text.trim(),
        subcategory: _subcategoryController.text.trim(),
        itemName: _itemNameController.text.trim(),
        code: _codeController.text.trim(),
        mrp: double.tryParse(_mrpController.text.trim()) ?? 0.0,
        tax: double.tryParse(_taxController.text.trim()) ?? 0.0,
        managerDiscount:
            double.tryParse(_managerDiscountController.text.trim()) ?? 0.0,
        salesmanDiscount:
            double.tryParse(_salesmanDiscountController.text.trim()) ?? 0.0,
        imageUrl: widget.product.imageUrl, // updated below if new image selected
      );
      final productService =
          Provider.of<ProductService>(context, listen: false);
      await productService.updateProduct(
          widget.product.id, updatedProduct.toJson(), _selectedImage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        setState(() {
          isEditing = false;
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickNewImage() async {
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

  void _startEditing() {
    setState(() {
      isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      _selectedImage = null;
      _resetControllers();
    });
  }

  void _resetControllers() {
    _categoryController.text = widget.product.category;
    _subcategoryController.text = widget.product.subcategory;
    _itemNameController.text = widget.product.itemName;
    _codeController.text = widget.product.code;
    _mrpController.text = widget.product.mrp.toString();
    _taxController.text = widget.product.tax.toString();
    _managerDiscountController.text =
        widget.product.managerDiscount.toString();
    _salesmanDiscountController.text =
        widget.product.salesmanDiscount.toString();
  }

  Widget _buildProductDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: widget.product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.product.imageUrl,
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 180),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 180,
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  )
                : const Icon(Icons.image_not_supported, size: 180),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Category', widget.product.category),
          _buildDetailRow('Subcategory', widget.product.subcategory),
          _buildDetailRow('Item Name', widget.product.itemName),
          _buildDetailRow('Code', widget.product.code),
          _buildDetailRow('MRP', '₹${widget.product.mrp.toStringAsFixed(2)}'),
          _buildDetailRow('Tax', '${widget.product.tax.toStringAsFixed(2)}%'),
          _buildDetailRow('Manager Discount',
              '${widget.product.managerDiscount.toStringAsFixed(2)}%'),
          _buildDetailRow('Salesman Discount',
              '${widget.product.salesmanDiscount.toStringAsFixed(2)}%'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.product.imageUrl,
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 180),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                            ),
                          )
                        : const Icon(Icons.image_not_supported, size: 180),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    onPressed: _pickNewImage,
                    tooltip: 'Change Image',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildEditTextField(_categoryController, 'Category'),
          _buildEditTextField(_subcategoryController, 'Subcategory'),
          _buildEditTextField(_itemNameController, 'Item Name'),
          _buildEditTextField(_codeController, 'Code', isReadOnly: true),
          _buildEditTextField(_mrpController, 'MRP', isNumber: true),
          _buildEditTextField(_taxController, 'Tax (%)', isNumber: true),
          _buildEditTextField(
              _managerDiscountController, 'Manager Discount (%)',
              isNumber: true),
          _buildEditTextField(
              _salesmanDiscountController, 'Salesman Discount (%)',
              isNumber: true),
        ],
      ),
    );
  }

  Widget _buildEditTextField(TextEditingController controller, String label,
      {bool isNumber = false, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        readOnly: isReadOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isAdmin = userProvider.user?.role == UserRoles.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Product Details'),
        actions: isAdmin
            ? (isEditing
                ? [
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveEdits,
                      tooltip: 'Save Changes',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: _cancelEditing,
                      tooltip: 'Cancel Editing',
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _startEditing,
                      tooltip: 'Edit Product',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deleteProduct,
                      tooltip: 'Delete Product',
                    ),
                  ])
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: isEditing ? _buildEditForm() : _buildProductDetails(),
            ),
    );
  }
}
