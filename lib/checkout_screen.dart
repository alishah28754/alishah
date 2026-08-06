// lib/pages/checkout_screen.dart
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

class CheckoutScreen extends StatefulWidget {
  final List<Product> products;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.products,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _transactionIdController = TextEditingController();

  String _selectedPaymentMethod = 'easypaisa';
  int _currentStep = 0;
  bool _showClaimCode = false;
  File? _screenshotImage;
  bool _isImageUploaded = false;

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

  int _getItemQuantity(String productId) {
    final cart = CartScope.of(context);
    final cartItem = cart.items.firstWhere(
          (item) => item.id == productId,
      orElse: () => CartItem(
        id: productId,
        name: '',
        price: 0,
        imageUrl: '',
        quantity: 1,
      ),
    );
    return cartItem.quantity;
  }

  double _getTotalWithQuantities() {
    double total = 0;
    for (var p in widget.products) {
      final cart = CartScope.of(context);
      final cartItem = cart.items.firstWhere(
            (item) => item.id == p.id,
        orElse: () => CartItem(
          id: p.id,
          name: p.name,
          price: p.price,
          imageUrl: p.imageUrl,
          quantity: 1,
        ),
      );
      total += p.price * cartItem.quantity;
    }
    return total;
  }

  double get deliveryFee {
    final total = _getTotalWithQuantities();
    return total >= 5000 ? 0 : 300;
  }

  double get totalPrice => _getTotalWithQuantities() + deliveryFee;
  bool get isDeliveryFree => _getTotalWithQuantities() >= 5000;

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
  // ✅ FIXED: WHATSAPP SHARING
  // ============================================================
  Future<void> _shareOnWhatsApp(String orderId, String status) async {
    final itemsList = widget.products.map((p) {
      final cart = CartScope.of(context);
      final cartItem = cart.items.firstWhere(
            (item) => item.id == p.id,
        orElse: () => CartItem(
          id: p.id,
          name: p.name,
          price: p.price,
          imageUrl: p.imageUrl,
          quantity: 1,
        ),
      );
      return '${cartItem.quantity}x ${p.name} - Rs.${(p.price * cartItem.quantity).toStringAsFixed(0)}';
    }).join('\n');

    double totalWithQuantities = 0;
    for (var p in widget.products) {
      final cart = CartScope.of(context);
      final cartItem = cart.items.firstWhere(
            (item) => item.id == p.id,
        orElse: () => CartItem(
          id: p.id,
          name: p.name,
          price: p.price,
          imageUrl: p.imageUrl,
          quantity: 1,
        ),
      );
      totalWithQuantities += p.price * cartItem.quantity;
    }
    final finalTotal = totalWithQuantities + deliveryFee;

    final String message = '''
🛍️ *K-TEX ORDER DETAILS*
━━━━━━━━━━━━━━━━━━━━━

👤 *Customer Details*
Name: ${_nameController.text.trim()}
Email: ${_emailController.text.trim()}
Phone: ${_phoneController.text.trim()}
Address: ${_addressController.text.trim()}, ${_cityController.text.trim()}
${_zipController.text.isNotEmpty ? 'ZIP Code: ${_zipController.text.trim()}' : ''}

📦 *Order Items*
$itemsList

📊 *Order Summary*
Order ID: $orderId
Total Items: ${widget.products.fold<int>(0, (sum, p) {
      final cart = CartScope.of(context);
      final cartItem = cart.items.firstWhere(
            (item) => item.id == p.id,
        orElse: () => CartItem(
          id: p.id,
          name: p.name,
          price: p.price,
          imageUrl: p.imageUrl,
          quantity: 1,
        ),
      );
      return sum + cartItem.quantity;
    })}
Subtotal: Rs.${totalWithQuantities.toStringAsFixed(0)}
Delivery: ${isDeliveryFree ? 'FREE' : 'Rs. 300'}
Total: Rs.${finalTotal.toStringAsFixed(0)}
Status: $status
💳 *Payment Method*
${_selectedPaymentMethod.toUpperCase()}

${_transactionIdController.text.isNotEmpty ? 'Transaction ID: ${_transactionIdController.text.trim()}' : ''}

${isDeliveryFree ? 'Free Delivery Applied!' : ''}
━━━━━━━━━━━━━━━━━━━━━
Thank you for shopping at K-TEX! 
''';

    final String phoneNumber = '923269873271';
    final String encodedMessage = Uri.encodeComponent(message);

    bool whatsAppOpened = false;

    // Direct WhatsApp app intent
    try {
      final String waIntent = 'whatsapp://send?phone=$phoneNumber&text=$encodedMessage';
      final uri = Uri.parse(waIntent);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        whatsAppOpened = true;
      }
    } catch (e) {}

    // Fallback: wa.me
    if (!whatsAppOpened) {
      try {
        final String webUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
        final uri = Uri.parse(webUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          whatsAppOpened = true;
        }
      } catch (e) {}
    }

    if (mounted) {
      if (whatsAppOpened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order confirmed! Redirecting to home...'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToHome();
          }
        });
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open WhatsApp. Order details copied to clipboard!'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToHome();
          }
        });
      }
    }
  }

  // ============================================================
  // ✅ UPDATED: Place Order
  // ============================================================
  void _placeOrder() {
    HapticFeedback.mediumImpact();

    final orderId = 'KTX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final trackingId = 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    double orderTotal = 0;
    final orderItems = widget.products.map((p) {
      final cart = CartScope.of(context);
      final cartItem = cart.items.firstWhere(
            (item) => item.id == p.id,
        orElse: () => CartItem(
          id: p.id,
          name: p.name,
          price: p.price,
          imageUrl: p.imageUrl,
          quantity: 1,
        ),
      );
      orderTotal += p.price * cartItem.quantity;
      return OrderItem(
        name: p.name,
        price: p.price,
        quantity: cartItem.quantity,
        imageUrl: p.imageUrl,
      );
    }).toList();

    final totalWithDelivery = orderTotal + deliveryFee;

    final order = Order(
      id: orderId,
      date: DateTime.now().toString().split(' ')[0],
      items: widget.products.fold<int>(
        0,
            (sum, p) {
          final cart = CartScope.of(context);
          final cartItem = cart.items.firstWhere(
                (item) => item.id == p.id,
            orElse: () => CartItem(
              id: p.id,
              name: p.name,
              price: p.price,
              imageUrl: p.imageUrl,
              quantity: 1,
            ),
          );
          return sum + cartItem.quantity;
        },
      ),
      total: totalWithDelivery.toInt(),
      status: 'Processing',
      payment: _selectedPaymentMethod,
      tracking: trackingId,
      image: widget.products.isNotEmpty ? widget.products.first.imageUrl : '',
      orderItems: orderItems,
    );

    final orderModel = Provider.of<OrderModel>(context, listen: false);
    orderModel.addOrder(order);

    final cart = CartScope.of(context);
    cart.clear();

    if (_selectedPaymentMethod == 'cod') {
      _showCODWhatsAppDialog(order, orderId);
    } else {
      _showOnlinePaymentDialog(order, orderId);
    }
  }

  // ============================================================
  // ✅ FIXED: COD WhatsApp Dialog - Overflow Fixed
  // ============================================================
  void _showCODWhatsAppDialog(Order order, String orderId) {
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
            Text(
              'Order ID: $orderId\nTracking: ${order.tracking}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Confirm your order by sending the details via WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: AppColors.goldDark, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDeliveryFree ? '🎉 Free Delivery Applied!' : 'Delivery charges: Rs. 300',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Fixed: Overflow fix
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareOnWhatsApp(orderId, 'Processing');
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat, size: 20),
                    SizedBox(width: 8),
                    Flexible(
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
  // ✅ FIXED: Online Payment Dialog - Overflow Fixed
  // ============================================================
  void _showOnlinePaymentDialog(Order order, String orderId) {
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
            Text(
              'Order ID: $orderId\nTracking: ${order.tracking}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: AppColors.goldDark, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDeliveryFree ? '🎉 Free Delivery Applied!' : 'Delivery charges: Rs. 300',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Fixed: Overflow fix
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareOnWhatsApp(orderId, 'Processing');
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat, size: 20),
                    SizedBox(width: 8),
                    Flexible(
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
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
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
          'Checkout',
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
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildOrderSummary(),
                  const SizedBox(height: 20),
                  _buildStepContent(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: cardColor,
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
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.gold : cardColor,
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

  Widget _buildOrderSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    double totalWithQuantities = 0;
    for (var p in widget.products) {
      final cart = CartScope.of(context);
      final cartItem = cart.items.firstWhere(
            (item) => item.id == p.id,
        orElse: () => CartItem(
          id: p.id,
          name: p.name,
          price: p.price,
          imageUrl: p.imageUrl,
          quantity: 1,
        ),
      );
      totalWithQuantities += p.price * cartItem.quantity;
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.products.map((product) {
            final cart = CartScope.of(context);
            final cartItem = cart.items.firstWhere(
                  (item) => item.id == product.id,
              orElse: () => CartItem(
                id: product.id,
                name: product.name,
                price: product.price,
                imageUrl: product.imageUrl,
                quantity: 1,
              ),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      product.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 40,
                        height: 40,
                        color: AppColors.surfaceContainerHigh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${cartItem.quantity}x ${product.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    'Rs.${(product.price * cartItem.quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: mutedColor,
                ),
              ),
              Text(
                'Rs.${totalWithQuantities.toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: mutedColor,
                ),
              ),
              Text(
                isDeliveryFree ? 'FREE' : 'Rs. 300',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDeliveryFree ? AppColors.goldDark : textColor,
                ),
              ),
            ],
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
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                'Rs.${(totalWithQuantities + deliveryFee).toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldDark,
                ),
              ),
            ],
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
            mutedColor: mutedColor,
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
            mutedColor: mutedColor,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildPhoneField(textColor, cardColor, mutedColor),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'Delivery Address',
            icon: Icons.location_on_outlined,
            hintText: 'Enter your delivery address',
            textColor: textColor,
            cardColor: cardColor,
            mutedColor: mutedColor,
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
                  mutedColor: mutedColor,
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
                  mutedColor: mutedColor,
                  validator: (value) => null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      ],
    );
  }

  Widget _buildConfirmOrder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Container(
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
              SizedBox(width: 10),
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
          _buildConfirmRow('Items', '${widget.products.length} products', textColor, mutedColor),
          _buildConfirmRow('Total', 'Rs.${totalPrice.toStringAsFixed(0)}', textColor, mutedColor),
          _buildConfirmRow('Delivery', isDeliveryFree ? 'Free' : 'Rs. 300', textColor, mutedColor),
          _buildConfirmRow('Payment', _selectedPaymentMethod, textColor, mutedColor),
          if (_transactionIdController.text.isNotEmpty)
            _buildConfirmRow('Transaction ID', _transactionIdController.text, textColor, mutedColor),
          const Divider(height: 20),
          Text(
            'Review your details carefully before confirming',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value, Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: mutedColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
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
    required Color mutedColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.06))
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

  Widget _buildPhoneField(Color textColor, Color cardColor, Color mutedColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.06))
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
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: textColor,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your phone number';
              if (!_isValidPhoneNumber(value)) return 'Enter valid phone number (e.g., 03XXXXXXXXX)';
              return null;
            },
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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : AppColors.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentStep == 2 ? 'Confirm Order' : 'Continue',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}