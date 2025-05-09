// lib/screens/admin/product_details_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
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

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  bool isEditing = false;
  bool _isLoading = false;
  File? _selectedImage;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

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
    _categoryController = TextEditingController(text: widget.product.category);
    _subcategoryController =
        TextEditingController(text: widget.product.subcategory);
    _itemNameController = TextEditingController(text: widget.product.itemName);
    _codeController = TextEditingController(text: widget.product.code);
    _mrpController = TextEditingController(text: widget.product.mrp.toString());
    _taxController = TextEditingController(text: widget.product.tax.toString());
    _managerDiscountController =
        TextEditingController(text: widget.product.managerDiscount.toString());
    _salesmanDiscountController =
        TextEditingController(text: widget.product.salesmanDiscount.toString());

    // Initialize animations
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();
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
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.product.itemName}"? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
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
          SnackBar(
            content: Text(
              'Product deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting product: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.shade700,
          ),
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
        SnackBar(
          content: Text(
            'Please fill all mandatory fields.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Save Changes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to save the changes?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
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
        imageUrl:
            widget.product.imageUrl, // updated below if new image selected
      );
      final productService =
          Provider.of<ProductService>(context, listen: false);
      await productService.updateProduct(
          widget.product.id, updatedProduct.toJson(), _selectedImage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product updated successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
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
    _managerDiscountController.text = widget.product.managerDiscount.toString();
    _salesmanDiscountController.text =
        widget.product.salesmanDiscount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isAdmin = userProvider.user?.role == UserRoles.admin;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                      tag: 'product-${widget.product.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                        ),
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : widget.product.imageUrl.isNotEmpty
                                ? Image.network(
                                    widget.product.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                      ),
                    ),
                    title: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      width: double.infinity,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        widget.product.itemName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 0, bottom: 0),
                    expandedTitleScale: 1.0,
                  ),
                  actions: [
                    if (isAdmin && !isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _startEditing,
                      ),
                    if (isAdmin && !isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: _deleteProduct,
                      ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: isEditing ? _buildEditForm() : _buildProductDetails(),
                ),
              ],
            ),
      bottomNavigationBar: isEditing
          ? FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _cancelEditing,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _saveEdits,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductDetails() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceCard(),
              const SizedBox(height: 24),
              _buildDetailsSection(),
              const SizedBox(height: 16),
              _buildDiscountSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade400,
              Colors.indigo.shade700,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MRP',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '₹${widget.product.mrp.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Tax: ${widget.product.tax}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Code', widget.product.code),
            const Divider(),
            _buildDetailRow('Category', widget.product.category),
            const Divider(),
            _buildDetailRow('Subcategory', widget.product.subcategory),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discount Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDiscountCard(
                    'Manager',
                    widget.product.managerDiscount,
                    Colors.green.shade100,
                    Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDiscountCard(
                    'Salesman',
                    widget.product.salesmanDiscount,
                    Colors.amber.shade100,
                    Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard(
      String title, double value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${value.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.discount, color: textColor, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return FadeIn(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditing)
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: Text(
                  'Change Image',
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _pickNewImage,
              ),
            const SizedBox(height: 24),
            Text(
              'Product Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
                _itemNameController, 'Item Name', Icons.inventory_2),
            _buildTextField(_categoryController, 'Category', Icons.category),
            _buildTextField(
                _subcategoryController, 'Subcategory', Icons.segment),
            _buildTextField(_codeController, 'Product Code', Icons.qr_code),
            _buildTextField(_mrpController, 'MRP (₹)', Icons.currency_rupee,
                isNumber: true),
            _buildTextField(_taxController, 'Tax (%)', Icons.receipt,
                isNumber: true),
            const SizedBox(height: 24),
            Text(
              'Discount Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(_managerDiscountController, 'Manager Discount (%)',
                Icons.person,
                isNumber: true),
            _buildTextField(_salesmanDiscountController,
                'Salesman Discount (%)', Icons.support_agent,
                isNumber: true),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
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
      ),
    );
  }
}
