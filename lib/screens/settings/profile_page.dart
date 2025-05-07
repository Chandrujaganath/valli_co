// lib/screens/settings/profile_page.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:z_emp/l10n/app_localizations.dart';
import 'package:z_emp/models/user_model.dart';
import 'package:z_emp/services/user_service.dart';
import 'package:z_emp/widgets/glassmorphic_container.dart';
import 'package:z_emp/widgets/neumorphic_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  UserModel? _currentUser;
  File? _imageFile;
  bool _isLoading = false;
  final _picker = ImagePicker();

  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final userService = Provider.of<UserService>(context, listen: false);
    final userModel = await userService.getUserById(authUser.uid);

    setState(() {
      _currentUser = userModel;
      _nameController = TextEditingController(text: userModel?.name ?? '');
      _mobileController = TextEditingController(text: userModel?.mobileNumber ?? '');
      _addressController = TextEditingController(text: userModel?.address ?? '');
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final fileName = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName.jpg');

      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user model with the new profile picture URL
      _currentUser!.profilePhotoUrl = '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      // Optionally, handle the error using your error reporting service.
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() != true || _currentUser == null) return;

    if (_imageFile != null) {
      await _uploadProfilePicture();
    }

    setState(() => _isLoading = true);

    _currentUser!
      ..name = _nameController.text.trim()
      ..mobileNumber = _mobileController.text.trim()
      ..address = _addressController.text.trim();

    final userService = Provider.of<UserService>(context, listen: false);
    await userService.updateUser(_currentUser!);

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );

    Navigator.of(context).pop();
  }

  void _showImageSourceActionSheet() {
    final appLocalization = AppLocalizations.of(context);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(appLocalization?.translate('choose_photo') ?? 'Choose photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
            child: Text(appLocalization?.translate('gallery') ?? 'Gallery'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: Text(appLocalization?.translate('camera') ?? 'Camera'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(appLocalization?.translate('cancel') ?? 'Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.white.withOpacity(0.2),
        border: null,
        middle: Text(
          loc?.translate('edit_profile') ?? 'Edit Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: backgroundGradient),
          ),
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _currentUser == null
                  ? const Center(child: Text('Loading...'))
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: GlassmorphicContainer(
                          borderRadius: 20,
                          blur: 15,
                          opacity: 0.2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                _buildProfileImage(),
                                const SizedBox(height: 20),
                                _buildEditImageButton(loc),
                                const SizedBox(height: 20),
                                _buildForm(loc),
                                const SizedBox(height: 30),
                                NeumorphicButton(
                                  text: loc?.translate('save') ?? 'Save',
                                  onPressed: _saveProfile,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final profileUrl = _currentUser?.profilePhotoUrl ?? '';
    return CircleAvatar(
      radius: 64,
      backgroundColor: Colors.white30,
      backgroundImage: _imageFile != null
          ? FileImage(_imageFile!)
          : profileUrl.isNotEmpty && profileUrl.startsWith('http')
              ? CachedNetworkImageProvider(profileUrl) as ImageProvider
              : const AssetImage('assets/images/default_profile.png'),
    );
  }

  Widget _buildEditImageButton(AppLocalizations? loc) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _showImageSourceActionSheet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.camera),
          const SizedBox(width: 8),
          Text(loc?.translate('upload_profile_picture') ?? 'Change Photo'),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations? loc) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc?.translate('name') ?? 'Name',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CupertinoTextFormFieldRow(
            controller: _nameController,
            placeholder: loc?.translate('enter_name') ?? 'Enter your name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            loc?.translate('mobile_number') ?? 'Mobile Number',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CupertinoTextFormFieldRow(
            controller: _mobileController,
            placeholder: loc?.translate('enter_mobile_number') ?? 'Enter your mobile number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Text(
            loc?.translate('address') ?? 'Address',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CupertinoTextFormFieldRow(
            controller: _addressController,
            placeholder: loc?.translate('enter_address') ?? 'Enter your address',
            keyboardType: TextInputType.streetAddress,
          ),
        ],
      ),
    );
  }
}
