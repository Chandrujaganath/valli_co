// lib/screens/admin/geo_fence_management_screen.dart
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/attendance_service.dart';
import '../../models/geo_fence_model.dart';

class GeoFenceManagementScreen extends StatefulWidget {
  const GeoFenceManagementScreen({super.key});

  @override
  _GeoFenceManagementScreenState createState() => _GeoFenceManagementScreenState();
}

class _GeoFenceManagementScreenState extends State<GeoFenceManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _locationName = '';
  String _latitude = '';
  String _longitude = '';
  String _radius = '';
  bool _isSubmitting = false;

  Future<void> _addGeoFence() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final double latitude = double.parse(_latitude);
      final double longitude = double.parse(_longitude);
      final double radius = double.parse(_radius);

      setState(() {
        _isSubmitting = true;
      });

      try {
        final attendanceService = Provider.of<AttendanceService>(context, listen: false);
        await attendanceService.addGeoFence(
          GeoPoint(latitude, longitude),
          radius,
          _locationName,
        );
        _showSnackBar('Geo-fence added successfully.');
        _formKey.currentState!.reset();
        setState(() {
          _locationName = '';
          _latitude = '';
          _longitude = '';
          _radius = '';
        });
      } catch (e) {
        _showSnackBar('Error adding geo-fence: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Future<void> _deleteGeoFence(String geoFenceId) async {
    try {
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      await attendanceService.deleteGeoFence(geoFenceId);
      _showSnackBar('Geo-fence deleted successfully.');
      if (mounted) setState(() {}); // Refresh the UI
    } catch (e) {
      _showSnackBar('Error deleting geo-fence: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceService = Provider.of<AttendanceService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo-fence Management'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE4EBF5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Form to add a new geo-fence inside an elevated Card.
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          'Add New Geo-fence',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Location Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a location name';
                            }
                            return null;
                          },
                          onSaved: (value) => _locationName = value!,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter latitude';
                            }
                            return null;
                          },
                          onSaved: (value) => _latitude = value!,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter longitude';
                            }
                            return null;
                          },
                          onSaved: (value) => _longitude = value!,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Radius (meters)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter radius';
                            }
                            return null;
                          },
                          onSaved: (value) => _radius = value!,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _addGeoFence,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add Geo-fence'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Existing Geo-fences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // The list of geo-fences occupies the remaining height.
              Expanded(
                child: FutureBuilder<List<GeoFenceModel>>(
                  future: attendanceService.getGeoFences(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text('Error loading geo-fences.'));
                    } else if (snapshot.data!.isEmpty) {
                      return const Center(child: Text('No geo-fences found.'));
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final geoFence = snapshot.data![index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              title: Text(
                                geoFence.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Lat: ${geoFence.location.latitude.toStringAsFixed(4)}, Long: ${geoFence.location.longitude.toStringAsFixed(4)}\nRadius: ${geoFence.radius.toInt()} meters',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteGeoFence(geoFence.id),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Show a loading overlay if submitting.
      floatingActionButton: _isSubmitting
          ? Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
