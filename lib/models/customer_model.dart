// lib/models/customer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String customerId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final Timestamp registrationDate;

  CustomerModel({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.registrationDate,
  });

  factory CustomerModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      customerId: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      registrationDate: data['registrationDate'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'registrationDate': registrationDate,
    };
  }
}
