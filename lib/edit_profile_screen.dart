import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;
  final String? userImage;
  final Function(String, String, String, String?) onSave;

  const EditProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    this.userImage,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    _phoneController.text = widget.userPhone;

    if (widget.userImage != null && widget.userImage!.isNotEmpty) {
      final file = File(widget.userImage!);
      if (file.existsSync()) {
        _imageFile = file;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = '${directory.path}/$fileName';

        final File savedImage = await File(image.path).copy(filePath);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImage', savedImage.path);

        setState(() {
          _imageFile = savedImage;
        });

        print('✅ Image saved to: ${savedImage.path}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image updated successfully!'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImage');
    setState(() {
      _imageFile = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed successfully'),
        backgroundColor: AppColors.gold,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      final String imagePath = _imageFile?.path ?? '';
      widget.onSave(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        imagePath.isNotEmpty ? imagePath : null,
      );
      Navigator.pop(context, imagePath.isNotEmpty ? imagePath : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;
    final hintColor = isDark ? Colors.white38 : AppColors.outline.withOpacity(0.6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        border: Border.all(
                          color: AppColors.gold,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _imageFile != null && _imageFile!.existsSync()
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.file(
                          _imageFile!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Icon(
                        Icons.person,
                        size: 60,
                        color: isDark ? Colors.white54 : AppColors.outline,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Remove Image Button
              if (_imageFile != null)
                GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.red.withOpacity(0.6) : Colors.red.withOpacity(0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: isDark ? Colors.red.shade300 : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Remove Image',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: isDark ? Colors.red.shade300 : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                hintText: 'Enter your full name',
                textColor: textColor,
                cardColor: cardColor,
                hintColor: hintColor,
                mutedColor: mutedColor,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                textColor: textColor,
                cardColor: cardColor,
                hintColor: hintColor,
                mutedColor: mutedColor,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                hintText: 'Enter your phone number',
                keyboardType: TextInputType.phone,
                textColor: textColor,
                cardColor: cardColor,
                hintColor: hintColor,
                mutedColor: mutedColor,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    required Color textColor,
    required Color cardColor,
    required Color hintColor,
    required Color mutedColor,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.08))
                : null,
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: textColor,
            ),
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.goldDark),
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: hintColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isDark ? Colors.red.shade300 : Colors.red,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}