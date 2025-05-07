// lib/screens/sales_staff/job_enquiry_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/enquiry_service.dart';
import '../../models/enquiry_model.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../providers/user_provider.dart';

// Import localization
import '../../l10n/app_localizations.dart';

class JobEnquiryScreen extends StatefulWidget {
  const JobEnquiryScreen({super.key});

  @override
  State<JobEnquiryScreen> createState() => _JobEnquiryScreenState();
}

class _JobEnquiryScreenState extends State<JobEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController enquiryNameController = TextEditingController();
  final TextEditingController specificProductSceneController =
      TextEditingController();

  bool isExistingCustomer = false;
  CustomerModel? selectedCustomer;
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  final TextEditingController customerAddressController =
      TextEditingController();

  List<ProductModel> products = [];
  List<String> productCategories = [];
  String? selectedProductCategory;

  String status = 'Enquiry';
  DateTime? enquiryDate;
  String? selectedMeasurementStaff;

  final TextEditingController numMaleCustomersController =
      TextEditingController();
  final TextEditingController numFemaleCustomersController =
      TextEditingController();
  final TextEditingController numChildrenCustomersController =
      TextEditingController();

  List<CustomerModel> customers = [];

  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCustomers();
  }

  /// Show an error dialog
  void _showErrorDialog(String message) {
    final appLocalization = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLocalization?.translate('error') ?? 'Error'),
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
            child: Text(appLocalization?.translate('close') ?? 'Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final productService =
          Provider.of<ProductService>(context, listen: false);
      final fetchedProducts = await productService.getAllProductsOnce();
      if (!mounted) return;
      setState(() {
        products = fetchedProducts;
        _extractCategories();
      });
    } catch (e) {
      if (!mounted) return;
      _hasError = true;
      _errorMessage = 'Failed to load products: $e';
      _showErrorDialog(_errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customerService =
          Provider.of<CustomerService>(context, listen: false);
      final fetchedCustomers = await customerService.getAllCustomersOnce();
      if (!mounted) return;
      setState(() {
        customers = fetchedCustomers;
      });
    } catch (e) {
      if (!mounted) return;
      _hasError = true;
      _errorMessage = 'Failed to load customers: $e';
      _showErrorDialog(_errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _extractCategories() {
    final categories = products.map((p) => p.category).toSet().toList();
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    productCategories = categories;
  }

  /// Pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadProducts();
    await _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    // Status items
    final statusItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'Enquiry',
        child: Text(
          appLocalization?.translate('enquiry') ?? 'Enquiry',
        ),
      ),
      DropdownMenuItem(
        value: 'Follow-up',
        child: Text(
          appLocalization?.translate('follow_up') ?? 'Follow-up',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appLocalization?.translate('job_enquiries') ?? 'Job Enquiries',
        ),
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
                colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      appLocalization?.translate('create_new_job_enquiry') ??
                          'Create New Job Enquiry',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Customer type & fields
                    _buildCustomerSelection(context),
                    const SizedBox(height: 16.0),

                    // Enquiry date
                    _buildEnquiryDateField(context),
                    const SizedBox(height: 16.0),

                    // Region
                    TextFormField(
                      controller: regionController,
                      decoration: InputDecoration(
                        labelText: appLocalization?.translate('area_label') ??
                            'Area *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? appLocalization?.translate('enter_area') ??
                              'Please enter area'
                          : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Product category
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return productCategories.where((category) => category
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: appLocalization
                                    ?.translate('product_category_label') ??
                                'Product Category *',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              (selectedProductCategory == null ||
                                      selectedProductCategory!.isEmpty)
                                  ? appLocalization?.translate(
                                        'select_product_category',
                                      ) ??
                                      'Please select a product category'
                                  : null,
                        );
                      },
                      onSelected: (String selection) {
                        if (!mounted) return;
                        setState(() {
                          selectedProductCategory = selection;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Specific product scene
                    TextFormField(
                      controller: specificProductSceneController,
                      decoration: InputDecoration(
                        labelText: appLocalization?.translate(
                              'specific_product_scene_label',
                            ) ??
                            'Specific Product Scene *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? appLocalization?.translate(
                                'enter_specific_product_scene',
                              ) ??
                              'Please enter specific product scene'
                          : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Number of customers
                    _buildNumberOfCustomersSection(context),
                    const SizedBox(height: 16.0),

                    // Status
                    DropdownButtonFormField<String>(
                      value: status,
                      items: statusItems,
                      onChanged: (value) {
                        if (value != null) {
                          if (!mounted) return;
                          setState(() {
                            status = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: appLocalization?.translate('status_label') ??
                            'Status *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? appLocalization?.translate('select_status') ??
                              'Please select a status'
                          : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Remarks
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText:
                            appLocalization?.translate('remarks') ?? 'Remarks',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16.0),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await _saveEnquiry();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              appLocalization
                                      ?.translate('save_enquiry_button') ??
                                  'Save Enquiry',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnquiryDateField(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    String labelText;
    if (enquiryDate != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(enquiryDate!);
      labelText =
          '${appLocalization?.translate('enquiry_date_label') ?? 'Enquiry Date *'} ($formatted)';
    } else {
      labelText =
          appLocalization?.translate('enquiry_date_label') ?? 'Enquiry Date *';
    }

    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        DateTime initialDate = enquiryDate ?? DateTime.now();
        DateTime firstDate = DateTime(2000);
        DateTime lastDate = DateTime.now();

        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (pickedDate != null && pickedDate != enquiryDate) {
          if (!mounted) return;
          setState(() {
            enquiryDate = pickedDate;
          });
        }
      },
      validator: (value) => enquiryDate == null
          ? appLocalization?.translate('select_enquiry_date') ??
              'Please select enquiry date'
          : null,
    );
  }

  Future<void> _saveEnquiry() async {
    final appLocalization = AppLocalizations.of(context);

    final enquiryService = Provider.of<EnquiryService>(context, listen: false);
    final customerService =
        Provider.of<CustomerService>(context, listen: false);
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    setState(() => _isLoading = true);

    try {
      String customerId = '';
      if (isExistingCustomer && selectedCustomer != null) {
        customerId = selectedCustomer!.customerId;
      }
      if (!isExistingCustomer) {
        // Create new customer
        final newCustomerId =
            FirebaseFirestore.instance.collection('customers').doc().id;
        final newCustomer = CustomerModel(
          customerId: newCustomerId,
          name: customerNameController.text,
          phone: phoneNumberController.text,
          email: customerEmailController.text,
          address: customerAddressController.text,
          registrationDate: Timestamp.now(),
        );
        await customerService.addCustomer(newCustomer);
        customerId = newCustomerId;
      }
      final enquiryId =
          FirebaseFirestore.instance.collection('enquiries').doc().id;

      final newEnquiry = EnquiryModel(
        enquiryId: enquiryId,
        enquiryName: selectedProductCategory ?? 'No Name',
        customerId: customerId,
        customerName: isExistingCustomer
            ? (selectedCustomer?.name ?? '')
            : customerNameController.text,
        phoneNumber: isExistingCustomer
            ? (selectedCustomer?.phone ?? '')
            : phoneNumberController.text,
        customerEmail: customerEmailController.text,
        customerAddress: isExistingCustomer
            ? (selectedCustomer?.address ?? '')
            : customerAddressController.text,
        region: regionController.text,
        product: selectedProductCategory ?? '',
        assignedSalesPerson: currentUser?.name ?? '',
        assignedSalesPersonId: currentUser?.userId ?? '',
        numMaleCustomers: int.tryParse(numMaleCustomersController.text) ?? 0,
        numFemaleCustomers:
            int.tryParse(numFemaleCustomersController.text) ?? 0,
        numChildrenCustomers:
            int.tryParse(numChildrenCustomersController.text) ?? 0,
        status: status,
        remarks: remarksController.text,
        enquiryDate: Timestamp.fromDate(enquiryDate!),
        timeIn: Timestamp.now(),
        timeOut: null,
        assignedMeasurementStaff: null,
        specificProductScene: specificProductSceneController.text,
      );

      await enquiryService.createJobEnquiry(newEnquiry);

      // Reset fields
      _formKey.currentState!.reset();
      setState(() {
        isExistingCustomer = false;
        selectedCustomer = null;
        selectedProductCategory = null;
        enquiryDate = null;
        status = 'Enquiry';
        selectedMeasurementStaff = null;
        phoneNumberController.clear();
        remarksController.clear();
        regionController.clear();
        customerNameController.clear();
        customerEmailController.clear();
        customerAddressController.clear();
        numMaleCustomersController.clear();
        numFemaleCustomersController.clear();
        numChildrenCustomersController.clear();
        specificProductSceneController.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalization?.translate('job_enquiry_created_success') ??
                'Job enquiry created successfully',
          ),
        ),
      );
    } catch (e) {
      _hasError = true;
      _errorMessage =
          '${appLocalization?.translate('error_creating_job_enquiry') ?? 'Error creating job enquiry'}: $e';
      _showErrorDialog(_errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomerSelection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalization?.translate('customer_type_label') ?? 'Customer Type:',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: Text(
                appLocalization?.translate('existing_customer') ?? 'Existing',
              ),
              selected: isExistingCustomer,
              onSelected: (selected) {
                if (!mounted) return;
                setState(() {
                  isExistingCustomer = true;
                  selectedCustomer = null;
                  customerNameController.clear();
                  customerEmailController.clear();
                  customerAddressController.clear();
                  phoneNumberController.clear();
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(
                appLocalization?.translate('new_customer') ?? 'New',
              ),
              selected: !isExistingCustomer,
              onSelected: (selected) {
                if (!mounted) return;
                setState(() {
                  isExistingCustomer = false;
                  selectedCustomer = null;
                  customerNameController.clear();
                  customerEmailController.clear();
                  customerAddressController.clear();
                  phoneNumberController.clear();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isExistingCustomer)
          _buildExistingCustomerFields(context)
        else
          _buildNewCustomerFields(context),
      ],
    );
  }

  Widget _buildExistingCustomerFields(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    return Column(
      children: [
        Autocomplete<CustomerModel>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<CustomerModel>.empty();
            }
            return customers.where((CustomerModel customer) => customer.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          displayStringForOption: (CustomerModel option) => option.name,
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: appLocalization?.translate('customer_name_label') ??
                    'Customer Name *',
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (selectedCustomer == null &&
                      isExistingCustomer)
                  ? appLocalization?.translate('select_existing_customer') ??
                      'Please select a customer'
                  : null,
            );
          },
          onSelected: (CustomerModel selection) {
            if (!mounted) return;
            setState(() {
              selectedCustomer = selection;
              customerNameController.text = selection.name;
              customerEmailController.text = selection.email;
              customerAddressController.text = selection.address;
              phoneNumberController.text = selection.phone;
            });
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: customerEmailController,
          decoration: InputDecoration(
            labelText: appLocalization?.translate('email_label') ?? 'Email',
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: customerAddressController,
          decoration: InputDecoration(
            labelText: appLocalization?.translate('address_required_label') ??
                'Address *',
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
          validator: (value) => (value == null || value.isEmpty)
              ? appLocalization?.translate('address_is_required') ??
                  'Address is required'
              : null,
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: phoneNumberController,
          decoration: InputDecoration(
            labelText:
                appLocalization?.translate('phone_number_required_label') ??
                    'Phone Number *',
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
          validator: (value) => (value == null || value.isEmpty)
              ? appLocalization?.translate('phone_required') ??
                  'Phone number is required'
              : null,
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildNewCustomerFields(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    return Column(
      children: [
        TextFormField(
          controller: customerNameController,
          decoration: InputDecoration(
            labelText: appLocalization?.translate('customer_name_label') ??
                'Customer Name *',
            border: const OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? appLocalization?.translate('enter_customer_name') ??
                  'Please enter customer name'
              : null,
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: customerEmailController,
          decoration: InputDecoration(
            labelText: appLocalization?.translate('email_label') ?? 'Email',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) {
                return appLocalization?.translate('enter_valid_email') ??
                    'Please enter a valid email';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: customerAddressController,
          decoration: InputDecoration(
            labelText: appLocalization?.translate('address_required_label') ??
                'Address *',
            border: const OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? appLocalization?.translate('enter_address') ??
                  'Please enter an address'
              : null,
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: phoneNumberController,
          decoration: InputDecoration(
            labelText:
                appLocalization?.translate('phone_number_required_label') ??
                    'Phone Number *',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return appLocalization?.translate('phone_required') ??
                  'Please enter phone number';
            }
            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
              return appLocalization?.translate('enter_valid_10digit_phone') ??
                  'Please enter a valid 10-digit phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildNumberOfCustomersSection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalization?.translate('number_of_customers_label') ??
              'Number of Customers:',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: numMaleCustomersController,
                decoration: InputDecoration(
                  labelText: appLocalization?.translate('male_label') ?? 'Male',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextFormField(
                controller: numFemaleCustomersController,
                decoration: InputDecoration(
                  labelText:
                      appLocalization?.translate('female_label') ?? 'Female',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextFormField(
                controller: numChildrenCustomersController,
                decoration: InputDecoration(
                  labelText: appLocalization?.translate('children_label') ??
                      'Children',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    regionController.dispose();
    remarksController.dispose();
    customerNameController.dispose();
    customerEmailController.dispose();
    customerAddressController.dispose();
    numMaleCustomersController.dispose();
    numFemaleCustomersController.dispose();
    numChildrenCustomersController.dispose();
    enquiryNameController.dispose();
    specificProductSceneController.dispose();
    super.dispose();
  }
}
