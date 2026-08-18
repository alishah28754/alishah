// lib/pages/buy_now_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../cart_model.dart';
import '../models.dart';
import '../main_navigation_shell.dart';
import '../order_model.dart';

class BuyNowScreen extends StatefulWidget {
  final Product product;

  const BuyNowScreen({super.key, required this.product});

  @override
  State<BuyNowScreen> createState() => _BuyNowScreenState();
}

class _BuyNowScreenState extends State<BuyNowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _transactionIdController = TextEditingController();

  String _selectedPaymentMethod = 'easypaisa';
  String _selectedSize = 'M';
  int _quantity = 1;
  int _currentStep = 0;
  bool _showClaimCode = false;
  File? _screenshotImage;
  bool _isImageUploaded = false;

  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'easypaisa', 'name': 'Easypaisa', 'icon': Icons.wallet, 'color': const Color(0xFF0066B4)},
    {'id': 'jazzcash', 'name': 'JazzCash', 'icon': Icons.wallet, 'color': const Color(0xFFFF6B00)},
    {'id': 'bank', 'name': 'Bank Transfer', 'icon': Icons.account_balance, 'color': AppColors.primary},
    {'id': 'cod', 'name': 'Cash on Delivery', 'icon': Icons.payments_outlined, 'color': AppColors.goldDark},
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  double get subtotal => (widget.product.price * _quantity).toDouble();
  double get deliveryFee => subtotal >= 5000 ? 0 : 300;
  double get totalPrice => subtotal + deliveryFee;
  bool get isDeliveryFree => subtotal >= 5000;

  bool get isOnlinePayment =>
      _selectedPaymentMethod == 'easypaisa' ||
          _selectedPaymentMethod == 'jazzcash' ||
          _selectedPaymentMethod == 'bank';

  String? _validateTransactionId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter transaction ID';
    }

    final cleanId = value.trim();

    if (_selectedPaymentMethod == 'easypaisa') {
      final easyPaisaPattern = RegExp(r'^(EP)?[0-9]{10,12}$');
      if (!easyPaisaPattern.hasMatch(cleanId.replaceAll(RegExp(r'^EP'), ''))) {
        return 'Enter valid Easypaisa ID (10-12 digits)';
      }
    } else if (_selectedPaymentMethod == 'jazzcash') {
      final jazzCashPattern = RegExp(r'^(JC)?[0-9]{10,12}$');
      if (!jazzCashPattern.hasMatch(cleanId.replaceAll(RegExp(r'^JC'), ''))) {
        return 'Enter valid JazzCash ID (10-12 digits)';
      }
    } else if (_selectedPaymentMethod == 'bank') {
      final bankPattern = RegExp(r'^(BT)?[0-9]{8,16}$');
      if (!bankPattern.hasMatch(cleanId.replaceAll(RegExp(r'^BT'), ''))) {
        return 'Enter valid Bank Transaction ID (8-16 digits)';
      }
    }

    return null;
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      if (isOnlinePayment) {
        if (!_isImageUploaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload transaction screenshot'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final validationError = _validateTransactionId(_transactionIdController.text);
        if (validationError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      setState(() {
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      _placeOrder();
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _screenshotImage = File(image.path);
          _isImageUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot uploaded successfully!'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _screenshotImage = null;
      _isImageUploaded = false;
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainNavigationShell(),
      ),
          (route) => false,
    );
  }

  // ============================================================
  // ✅ UPDATED: WHATSAPP SHARING - Navigate to Home After Confirmation
  // ============================================================
  Future<void> _shareOnWhatsApp(Order order) async {
    final String message = '''
🛍️ *K-TEX ORDER DETAILS*
━━━━━━━━━━━━━━━━━━━━━

👤 *Customer Details*
Name: ${_nameController.text.trim()}
Email: ${_emailController.text.trim()}
Phone: ${_phoneController.text.trim()}
Address: ${_addressController.text.trim()}, ${_cityController.text.trim()}
${_zipController.text.isNotEmpty ? 'ZIP Code: ${_zipController.text.trim()}' : ''}

📦 *Order Details*
Product: ${widget.product.name}
Size: $_selectedSize
Quantity: $_quantity
Subtotal: Rs. ${subtotal.toStringAsFixed(0)}
Delivery: ${isDeliveryFree ? 'FREE' : 'Rs. 300'}
Total: Rs. ${totalPrice.toStringAsFixed(0)}

💳 *Payment Method*
${_selectedPaymentMethod.toUpperCase()}

${_transactionIdController.text.isNotEmpty ? 'Transaction ID: ${_transactionIdController.text.trim()}' : ''}

${isDeliveryFree ? '🎉 Free Delivery Applied!' : ''}

━━━━━━━━━━━━━━━━━━━━━
Thank you for shopping at K-TEX! 🙏
''';

    final String phoneNumber = '923269873271';
    final String encodedMessage = Uri.encodeComponent(message);

    bool whatsAppOpened = false;

    // Approach 1: whatsapp:// send intent (Best for Android)
    try {
      final String url = 'whatsapp://send?phone=$phoneNumber&text=$encodedMessage';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        whatsAppOpened = true;
      }
    } catch (e) {
      // Continue to next approach
    }

    // Approach 2: wa.me with platformDefault
    if (!whatsAppOpened) {
      try {
        final String url = 'https://wa.me/$phoneNumber?text=$encodedMessage';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          whatsAppOpened = true;
        }
      } catch (e) {
        // Continue to next approach
      }
    }

    // Approach 3: api.whatsapp.com with platformDefault
    if (!whatsAppOpened) {
      try {
        final String url = 'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          whatsAppOpened = true;
        }
      } catch (e) {
        // Continue to next approach
      }
    }

    // Approach 4: Try with externalApplication
    if (!whatsAppOpened) {
      try {
        final String url = 'https://wa.me/$phoneNumber?text=$encodedMessage';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          whatsAppOpened = true;
        }
      } catch (e) {
        // Continue to next approach
      }
    }

    // ✅ Navigate to Home AFTER WhatsApp opens (or if it fails)
    if (mounted) {
      if (whatsAppOpened) {
        // Show a brief success message then navigate home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order confirmed! Redirecting to home...'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToHome();
          }
        });
      } else {
        // Fallback: Copy to clipboard
        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open WhatsApp. Order details copied to clipboard!'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 3),
          ),
        );
        // Navigate to home after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToHome();
          }
        });
      }
    }
  }

  // ============================================================
  // ✅ UPDATED: Place Order - No Skip for COD
  // ============================================================
  void _placeOrder() {
    HapticFeedback.mediumImpact();

    final order = Order(
      id: 'KTX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      date: DateTime.now().toString().split(' ')[0],
      items: 1,
      total: totalPrice.toInt(),
      status: 'Processing',
      payment: _selectedPaymentMethod,
      tracking: 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      image: widget.product.imageUrl,
    );

    final orderModel = Provider.of<OrderModel>(context, listen: false);
    orderModel.addOrder(order);

    // ✅ For COD: Always go to WhatsApp, NO SKIP option
    if (_selectedPaymentMethod == 'cod') {
      _showCODWhatsAppDialog(order);
    } else {
      // For online payments: Show dialog with WhatsApp and Skip options
      _showOnlinePaymentDialog(order);
    }
  }

  // ============================================================
  // ✅ FIXED: COD WhatsApp Dialog - No Skip (Overflow fixed)
  // ============================================================
  void _showCODWhatsAppDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.goldContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.goldDark,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Confirm your order by sending the details via WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Fixed: Use SizedBox with full width instead of Expanded in Row
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareOnWhatsApp(order);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // ✅ Added to prevent overflow
                  children: [
                    Icon(Icons.chat, size: 20),
                    SizedBox(width: 8),
                    Flexible( // ✅ Flexible instead of direct Text to handle overflow
                      child: Text(
                        'Confirm on WhatsApp',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ FIXED: Online Payment Dialog - With Skip Option (Overflow fixed)
  // ============================================================
  void _showOnlinePaymentDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.goldContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.goldDark,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send confirmation via WhatsApp or continue to home.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Fixed: Use SizedBox with full width
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareOnWhatsApp(order);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // ✅ Added to prevent overflow
                  children: [
                    Icon(Icons.chat, size: 20),
                    SizedBox(width: 8),
                    Flexible( // ✅ Flexible instead of direct Text
                      child: Text(
                        'Send to WhatsApp',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Skip button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToHome();
              },
              child: const Text(
                'Skip & Continue',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buy Now',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.black),
                const SizedBox(width: 4),
                Text(
                  'Step ${_currentStep + 1}/3',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProductSummary(),
                    const SizedBox(height: 20),
                    _buildStepContent(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Row(
        children: [
          _buildStepCircle(0, 'Details', Icons.person_outline),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1 ? AppColors.gold : AppColors.outlineVariant,
            ),
          ),
          _buildStepCircle(1, 'Payment', Icons.payment_outlined),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2 ? AppColors.gold : AppColors.outlineVariant,
            ),
          ),
          _buildStepCircle(2, 'Confirm', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.gold : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
            border: Border.all(
              color: isActive ? AppColors.gold : AppColors.outlineVariant,
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? Icons.check : icon,
            color: isActive ? Colors.black : (isDark ? Colors.white : AppColors.outline),
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? AppColors.goldDark : (isDark ? Colors.white60 : AppColors.outline),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.product.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.surfaceContainerHigh,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${widget.product.price} × $_quantity',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Size: ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                    Text(
                      _selectedSize,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Qty: ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                    Text(
                      '$_quantity',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildShippingDetails();
      case 1:
        return _buildPaymentMethod();
      case 2:
        return _buildConfirmOrder();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildShippingDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            hintText: 'Enter your full name',
            textColor: textColor,
            cardColor: cardColor,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your name';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textColor: textColor,
            cardColor: cardColor,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildPhoneField(textColor, cardColor),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'Delivery Address',
            icon: Icons.location_on_outlined,
            hintText: 'Enter your delivery address',
            textColor: textColor,
            cardColor: cardColor,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your address';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  hintText: 'City',
                  textColor: textColor,
                  cardColor: cardColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter city';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _zipController,
                  label: 'ZIP Code (Optional)',
                  icon: Icons.pin_drop_outlined,
                  hintText: 'ZIP Code',
                  keyboardType: TextInputType.number,
                  textColor: textColor,
                  cardColor: cardColor,
                  validator: (value) => null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Select Size',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _sizes.map((size) {
              final isSelected = _selectedSize == size;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSize = size;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : (isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3)),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.gold.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black : textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Quantity:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                      icon: Icon(Icons.remove, color: textColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: Icon(Icons.add, color: textColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(Color textColor, Color cardColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: textColor,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              final cleanNumber = value.replaceAll(RegExp(r'[^0-9+]'), '');
              if (!_isValidPhoneNumber(cleanNumber)) {
                return 'Enter valid phone number (e.g., 03XX-XXXXXXX)';
              }
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              LengthLimitingTextInputFormatter(15),
            ],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.goldDark),
              hintText: '03XX-XXXXXXX',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: mutedColor.withOpacity(0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.gold,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Format: 03XX-XXXXXXX (Pakistan)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }

  bool _isValidPhoneNumber(String number) {
    String clean = number;
    if (clean.startsWith('+92')) {
      clean = clean.substring(3);
    }
    if (clean.length == 11 && clean.startsWith('03')) {
      return true;
    }
    if (clean.length == 10 && clean.startsWith('3')) {
      return true;
    }
    return false;
  }

  Widget _buildPaymentMethod() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your preferred payment method',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod == method['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method['id'];
                _showClaimCode = method['id'] == 'easypaisa' || method['id'] == 'jazzcash';
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withOpacity(0.1) : cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.gold : (isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold.withOpacity(0.2) : AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      method['icon'],
                      color: isSelected ? AppColors.goldDark : mutedColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['name'],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? textColor : mutedColor,
                          ),
                        ),
                        if (method['id'] == 'easypaisa')
                          const Text(
                            'Pay via Easypaisa wallet',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.outline,
                            ),
                          ),
                        if (method['id'] == 'jazzcash')
                          const Text(
                            'Pay via JazzCash wallet',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.goldDark,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
        if (isOnlinePayment) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.goldContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file_outlined, color: AppColors.goldDark),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Transaction Screenshot',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload screenshot of your payment transaction',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (_screenshotImage != null) ...[
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(_screenshotImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: _removeImage,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to upload screenshot',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (isOnlinePayment) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: _transactionIdController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: textColor,
                      ),
                      validator: _validateTransactionId,
                      decoration: InputDecoration(
                        hintText: 'Enter Transaction ID',
                        helperText: _selectedPaymentMethod == 'easypaisa'
                            ? 'Format: EPXXXXXXXXXX or 10-12 digits'
                            : _selectedPaymentMethod == 'jazzcash'
                            ? 'Format: JCXXXXXXXXXX or 10-12 digits'
                            : 'Format: BTXXXXXXXXXX or 8-16 digits',
                        helperStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: mutedColor,
                        ),
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: mutedColor.withOpacity(0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.goldDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPriceRow('Subtotal', 'Rs. ${subtotal.toStringAsFixed(0)}', textColor, mutedColor),
              const SizedBox(height: 8),
              _buildPriceRow(
                'Delivery Fee',
                isDeliveryFree ? 'FREE' : 'Rs. 300',
                textColor,
                mutedColor,
                color: isDeliveryFree ? AppColors.goldDark : null,
              ),
              if (isDeliveryFree) ...[
                const SizedBox(height: 4),
                const Text(
                  '🎉 Free delivery on orders above Rs. 5,000',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Divider(height: 24),
              _buildPriceRow(
                'Total',
                'Rs. ${totalPrice.toStringAsFixed(0)}',
                textColor,
                mutedColor,
                isBold: true,
                isLarge: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, Color textColor, Color mutedColor,
      {bool isBold = false, bool isLarge = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? textColor : mutedColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isLarge ? 20 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (isBold ? AppColors.goldDark : textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmOrder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withOpacity(0.15),
                AppColors.goldContainer.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.goldDark),
                  const SizedBox(width: 10),
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildConfirmRow('Product', widget.product.name, textColor, mutedColor),
              const SizedBox(height: 6),
              _buildConfirmRow('Size', _selectedSize, textColor, mutedColor),
              const SizedBox(height: 6),
              _buildConfirmRow('Quantity', '$_quantity', textColor, mutedColor),
              const SizedBox(height: 6),
              _buildConfirmRow('Payment', _selectedPaymentMethod, textColor, mutedColor),
              const SizedBox(height: 6),
              _buildConfirmRow('Delivery', isDeliveryFree ? 'Free' : 'Rs. 300', textColor, mutedColor),
              const SizedBox(height: 6),
              if (_transactionIdController.text.isNotEmpty)
                _buildConfirmRow('Transaction ID', _transactionIdController.text, textColor, mutedColor),
              const Divider(height: 20),
              _buildConfirmRow(
                'Total Amount',
                'Rs. ${totalPrice.toStringAsFixed(0)}',
                textColor,
                mutedColor,
                isBold: true,
                isLarge: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: AppColors.goldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'By placing this order, you agree to our Terms & Conditions',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(String label, String value, Color textColor, Color mutedColor,
      {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isLarge ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: mutedColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isLarge ? 16 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.goldDark : textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    required Color textColor,
    required Color cardColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isDark ? Border.all(color: Colors.white.withOpacity(0.06)) : null,
            boxShadow: isDark ? [] : [
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
              fontSize: 14,
              color: textColor,
            ),
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.goldDark),
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: mutedColor.withOpacity(0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == 2 ? 'Place Order' : 'Continue',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_currentStep != 2) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}