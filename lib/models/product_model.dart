// lib/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String category;
  final String subcategory;
  final String itemName;
  final String code;
  final double mrp;
  final double tax;
  final double managerDiscount;
  final double salesmanDiscount;
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.itemName,
    required this.code,
    required this.mrp,
    required this.tax,
    required this.managerDiscount,
    required this.salesmanDiscount,
    required this.imageUrl,
  });

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    return ProductModel(
      id: doc.id,
      category: doc['category'] ?? '',
      subcategory: doc['subcategory'] ?? '',
      itemName: doc['itemName'] ?? '',
      code: doc['code'] ?? '',
      mrp: (doc['mrp'] ?? 0).toDouble(),
      tax: (doc['tax'] ?? 0).toDouble(),
      managerDiscount: (doc['managerDiscount'] ?? 0).toDouble(),
      salesmanDiscount: (doc['salesmanDiscount'] ?? 0).toDouble(),
      imageUrl: doc['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subcategory': subcategory,
      'itemName': itemName,
      'code': code,
      'mrp': mrp,
      'tax': tax,
      'managerDiscount': managerDiscount,
      'salesmanDiscount': salesmanDiscount,
      'imageUrl': imageUrl,
    };
  }
}
