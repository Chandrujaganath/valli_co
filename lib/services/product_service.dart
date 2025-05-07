// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream to fetch all products in real-time
  Stream<List<ProductModel>> getProductsStream() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
    });
  }

  // Add a product
  Future<void> addProduct(ProductModel product, File? imageFile) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, product.code);
      }

      await _db.collection('products').add({
        ...product.toJson(),
        'imageUrl': imageUrl,
      });
    } catch (e) {
      print("Error adding product: $e");
      throw Exception("Failed to add product");
    }
  }

  // Update a product
  Future<void> updateProduct(String productId, Map<String, dynamic> productData, File? imageFile) async {
    try {
      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile, productData['code']);
        productData['imageUrl'] = imageUrl;
      }

      await _db.collection('products').doc(productId).update(productData);
    } catch (e) {
      print("Error updating product: $e");
      throw Exception("Failed to update product");
    }
  }

  // New method to get a product by its code
  Future<ProductModel?> getProductByCode(String code) async {
    try {
      final querySnapshot = await _db.collection('products').where('code', isEqualTo: code).get();
      if (querySnapshot.docs.isNotEmpty) {
        return ProductModel.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print("Error getting product by code: $e");
      return null;
    }
  }

  Future<String> _uploadImage(File imageFile, String code) async {
    try {
      final ref = _storage.ref().child('product_images/$code.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      rethrow; // Re-throw the exception for higher-level handling
    }
  }

// Optional: Add a cachedProducts property to avoid redundant fetches
List<ProductModel>? cachedProducts;

Future<List<ProductModel>> getAllProductsOnce() async {
  if (cachedProducts != null) {
    return cachedProducts!;
  }
  final snapshot = await _db.collection('products').get();
  cachedProducts = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
  return cachedProducts!;
}
// Delete a product
Future<void> deleteProduct(String productId, String imageUrl) async {
  try {
    // Delete image from Firebase Storage if it exists
    if (imageUrl.isNotEmpty) {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    }

    // Delete product document from Firestore
    await _db.collection('products').doc(productId).delete();
  } catch (e) {
    print("Error deleting product: $e");
    throw Exception("Failed to delete product");
  }
}
}
