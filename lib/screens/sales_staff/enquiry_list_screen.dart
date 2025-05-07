// lib/screens/sales_staff/enquiry_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/enquiry_service.dart';
import '../../services/follow_up_service.dart';
import '../../services/user_service.dart';
import '../../models/enquiry_model.dart';
import '../../models/follow_up_model.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  _EnquiryListScreenState createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  String searchQuery = '';
  bool _hasError = false;
  String _errorMessage = '';

  // Show an alert dialog for errors
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _hasError = false;
                _errorMessage = '';
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enquiryService = Provider.of<EnquiryService>(context, listen: false);
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    return Scaffold(
      // Premium gradient AppBar
      appBar: AppBar(
        title: const Text('Enquiry List'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE4EBF5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Enquiries',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                // Search Bar
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Enquiries',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    if (!mounted) return;
                    setState(() {
                      searchQuery = query;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                // List of Enquiries
                Expanded(
                  child: FutureBuilder<List<EnquiryModel>>(
                    future: enquiryService.getEnquiriesByUserId(
                      currentUser?.userId ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        // Show error dialog if not already shown
                        if (!_hasError) {
                          _hasError = true;
                          _errorMessage = snapshot.error.toString();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showErrorDialog(_errorMessage);
                          });
                        }
                        return const Center(
                          child: Text('Error retrieving enquiries.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text('No enquiries found.'),
                        );
                      }

                      final enquiries = snapshot.data!
                          .where((enquiry) => enquiry.customerName
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                          .toList();

                      if (enquiries.isEmpty) {
                        return const Center(child: Text('No enquiries found.'));
                      }

                      return ListView.builder(
                        itemCount: enquiries.length,
                        itemBuilder: (context, index) {
                          final enquiry = enquiries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                            child: ListTile(
                              title: Text(enquiry.customerName),
                              subtitle: Text('Status: ${enquiry.status}'),
                              trailing: Text(
                                DateFormat('yyyy-MM-dd')
                                    .format(enquiry.enquiryDate.toDate()),
                              ),
                              onTap: () => _showEnquiryDetails(enquiry),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Popup for capturing extra data
  Future<Map<String, Object>?> _showExtraDataPopup() async {
    final orderValueController = TextEditingController();
    final crNumberController = TextEditingController();
    DateTime? tatDate;
    final formKey = GlobalKey<FormState>();

    return await showDialog<Map<String, Object>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Enter Additional Details'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: orderValueController,
                        decoration: const InputDecoration(
                          labelText: 'Order Value',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: crNumberController,
                        decoration: const InputDecoration(
                          labelText: 'CR Number',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: dialogContext,
                            initialDate: tatDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              tatDate = pickedDate;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: tatDate == null
                                  ? 'Select Tat Date'
                                  : 'Tat Date: ${DateFormat('yyyy-MM-dd').format(tatDate!)}',
                            ),
                            validator: (value) {
                              if (tatDate == null) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() && tatDate != null) {
                      Navigator.pop(dialogContext, {
                        'orderValue': orderValueController.text.trim(),
                        'crNumber': crNumberController.text.trim(),
                        'tatDate': Timestamp.fromDate(tatDate!),
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEnquiryDetails(EnquiryModel enquiry) async {
    final followUpService =
        Provider.of<FollowUpService>(context, listen: false);
    final enquiryService = Provider.of<EnquiryService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    String newStatus = enquiry.status;
    String? selectedMeasurementStaff;
    bool statusDisabled = false;

    // Allowed transitions
    List<String> allowedStatuses = [];
    switch (enquiry.status) {
      case 'Enquiry':
        allowedStatuses = ['Enquiry', 'Follow-up'];
        break;
      case 'Follow-up':
        allowedStatuses = ['Follow-up', 'MTBT'];
        break;
      case 'MTBT':
        allowedStatuses = ['MTBT'];
        statusDisabled = true;
        break;
      case 'MOK':
        allowedStatuses = ['MOK', 'Sale done'];
        break;
      case 'Sale done':
        allowedStatuses = ['Sale done'];
        statusDisabled = true;
        break;
      default:
        allowedStatuses = [enquiry.status];
        break;
    }

    // showDialog for details
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            Future<List<UserModel>> measurementStaffFuture =
                userService.getUsersByRole('Measurement Staff');

            return AlertDialog(
              scrollable: true,
              title: const Text('Enquiry Details'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Name: ${enquiry.customerName}'),
                  Text('Phone: ${enquiry.phoneNumber}'),
                  Text('Product Category: ${enquiry.product}'),
                  Text(
                    'Specific Product Scene: ${enquiry.specificProductScene}',
                  ),
                  Text('Current Status: ${enquiry.status}'),
                  const SizedBox(height: 16.0),
                  // Status
                  DropdownButtonFormField<String>(
                    value: newStatus,
                    items: allowedStatuses
                        .map((statusOption) => DropdownMenuItem(
                              value: statusOption,
                              child: Text(statusOption),
                            ))
                        .toList(),
                    onChanged: statusDisabled
                        ? null
                        : (value) {
                            if (value != null) {
                              setStateDialog(() {
                                newStatus = value;
                              });
                            }
                          },
                    decoration: const InputDecoration(
                      labelText: 'Update Status',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // If user picks MTBT, require measurement staff selection
                  if (newStatus == 'MTBT')
                    FutureBuilder<List<UserModel>>(
                      future: measurementStaffFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Error loading measurement staff');
                        } else {
                          return DropdownButtonFormField<String>(
                            value: selectedMeasurementStaff,
                            items: snapshot.data!
                                .map((user) => DropdownMenuItem(
                                      value: user.userId,
                                      child: Text(user.name),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedMeasurementStaff = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Assign Measurement Staff',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please select measurement staff'
                                : null,
                          );
                        }
                      },
                    ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Follow-Ups',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<List<FollowUpModel>>(
                    future: followUpService
                        .getFollowUpsByEnquiry(enquiry.enquiryId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text('Error loading follow-ups.');
                      }
                      final followUps = snapshot.data!;
                      if (followUps.isEmpty) {
                        return const Text('No follow-ups found.');
                      }
                      return Column(
                        children: followUps.map((followUp) {
                          return ListTile(
                            title: Text(
                              'Date: ${DateFormat('yyyy-MM-dd').format(followUp.callDate.toDate())}',
                            ),
                            subtitle:
                                Text('Response: ${followUp.callResponse}'),
                            trailing: Text(
                              followUp.isPositive ? 'Positive' : 'Negative',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => _addFollowUp(enquiry.enquiryId),
                    child: const Text('Add Follow-Up'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                // Update Button
                if (!statusDisabled)
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);

                      // If newStatus == 'Sale done', require extra data
                      if (newStatus == 'Sale done') {
                        final extraData = await _showExtraDataPopup();
                        if (extraData != null) {
                          // If user provided
                          await enquiryService.updateEnquiryStatus(
                              enquiry.enquiryId, newStatus);
                          await enquiryService
                              .copyEnquiryToSalesHistoryWithExtraData(
                            enquiry,
                            extraData,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Enquiry status updated (Sale done).'),
                            ),
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Additional details not provided. Status remains unchanged.'),
                            ),
                          );
                        }
                      } else {
                        // Normal status update
                        await enquiryService.updateEnquiryStatus(
                            enquiry.enquiryId, newStatus);
                        // If user picks MTBT, optionally assign measurement staff
                        if (newStatus == 'MTBT' &&
                            selectedMeasurementStaff != null) {
                          await enquiryService.assignMeasurementTask(
                            enquiryId: enquiry.enquiryId,
                            measurementStaffId: selectedMeasurementStaff!,
                          );
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Enquiry status updated successfully'),
                          ),
                        );
                      }
                      setState(() {});
                    },
                    child: const Text('Update'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _addFollowUp(String enquiryId) {
    final callResponseController = TextEditingController();
    bool isPositiveResponse = true;
    DateTime? callDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Add Follow-Up'),
              content: Column(
                children: [
                  TextFormField(
                    controller: callResponseController,
                    decoration: const InputDecoration(
                      labelText: 'Call Response',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: callDate != null
                          ? 'Call Date: ${DateFormat('yyyy-MM-dd').format(callDate!)}'
                          : 'Select Call Date',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: dialogContext,
                        initialDate: callDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        if (!mounted) return;
                        setStateDialog(() {
                          callDate = pickedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Text('Response: '),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Positive'),
                          value: true,
                          groupValue: isPositiveResponse,
                          onChanged: (value) {
                            if (!mounted) return;
                            setStateDialog(() {
                              isPositiveResponse = value ?? true;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Negative'),
                          value: false,
                          groupValue: isPositiveResponse,
                          onChanged: (value) {
                            if (!mounted) return;
                            setStateDialog(() {
                              isPositiveResponse = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (callResponseController.text.isNotEmpty &&
                        callDate != null) {
                      final followUpService =
                          Provider.of<FollowUpService>(context, listen: false);
                      final newFollowUp = FollowUpModel(
                        followUpId: FirebaseFirestore.instance
                            .collection('followUps')
                            .doc()
                            .id,
                        enquiryId: enquiryId,
                        callDate: Timestamp.fromDate(callDate!),
                        callResponse: callResponseController.text,
                        isPositive: isPositiveResponse,
                      );
                      await followUpService.addFollowUp(newFollowUp);
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Follow-up added successfully')),
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
