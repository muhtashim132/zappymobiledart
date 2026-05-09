import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';
import '../../utils/validators.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Seller-specific
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopCategoryController = TextEditingController();
  final _gstController = TextEditingController();

  // Delivery-specific
  final _vehicleTypeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseController = TextEditingController();
  final _aadharController = TextEditingController();

  // Customer-specific
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedRole = 'customer';
  late AnimationController _roleAnim;
  late AnimationController _formAnim;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'customer',
      'label': 'Customer',
      'icon': Icons.shopping_bag_outlined,
      'desc': 'Order food & products',
      'color': const Color(0xFF0A2A9E),
      'gradient': const LinearGradient(
        colors: [Color(0xFF0A2A9E), Color(0xFF1E40AF)],
      ),
    },
    {
      'value': 'seller',
      'label': 'Seller',
      'icon': Icons.storefront_outlined,
      'desc': 'Sell your products',
      'color': const Color(0xFF6A1B9A),
      'gradient': AppColors.sellerGradient,
    },
    {
      'value': 'delivery_partner',
      'label': 'Delivery',
      'icon': Icons.delivery_dining_outlined,
      'desc': 'Earn by delivering',
      'color': const Color(0xFF00695C),
      'gradient': AppColors.deliveryGradient,
    },
  ];

  @override
  void initState() {
    super.initState();
    _roleAnim = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _formAnim = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnim =
        CurvedAnimation(parent: _formAnim, curve: Curves.easeIn);
    _formAnim.forward();
  }

  @override
  void dispose() {
    for (final c in [
      _nameController, _emailController, _phoneController,
      _passwordController, _shopNameController, _shopAddressController,
      _shopCategoryController, _gstController, _vehicleTypeController,
      _vehicleNumberController, _licenseController, _aadharController,
      _addressController,
    ]) {
      c.dispose();
    }
    _roleAnim.dispose();
    _formAnim.dispose();
    super.dispose();
  }

  void _switchRole(String role) {
    _formAnim.reset();
    setState(() => _selectedRole = role);
    _formAnim.forward();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic>? additionalData;
    if (_selectedRole == 'seller') {
      additionalData = {
        'shop_name': _shopNameController.text.trim(),
        'address': _shopAddressController.text.trim(),
        'category': _shopCategoryController.text.trim(),
        'gst_number': _gstController.text.trim(),
      };
    } else if (_selectedRole == 'delivery_partner') {
      additionalData = {
        'vehicle_type': _vehicleTypeController.text.trim(),
        'vehicle_number': _vehicleNumberController.text.trim(),
        'license_number': _licenseController.text.trim(),
        'aadhar_number': _aadharController.text.trim(),
      };
    } else {
      additionalData = {
        'address': _addressController.text.trim(),
      };
    }

    final error = await context.read<AuthProvider>().signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          additionalData: additionalData,
        );

    if (!mounted) return;

    if (error != null) {
      final bool alreadyExists = error.toLowerCase().contains('already') ||
          error.toLowerCase().contains('exists');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: alreadyExists
              ? SnackBarAction(
                  label: 'SIGN IN',
                  textColor: Colors.white,
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, AppRoutes.login),
                )
              : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_selectedRole == 'seller') {
      Navigator.pushReplacementNamed(context, AppRoutes.sellerDashboard);
    } else if (_selectedRole == 'delivery_partner') {
      Navigator.pushReplacementNamed(context, AppRoutes.deliveryDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final activeRole = _roles.firstWhere((r) => r['value'] == _selectedRole);
    final roleColor = activeRole['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A2A9E),
                    Color(0xFF071D6B),
                    Color(0xFF050F3A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Back + title row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFE5A800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF4C542).withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Join the Zappy Family!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Role Selector ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: _roles.map((role) {
                          final isSelected = _selectedRole == role['value'];
                          final color = role['color'] as Color;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _switchRole(role['value'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      role['icon'] as IconData,
                                      color: isSelected
                                          ? color
                                          : Colors.white.withOpacity(0.7),
                                      size: 26,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      role['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? color
                                            : Colors.white.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      role['desc'] as String,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isSelected
                                            ? Colors.grey[600]
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: roleColor.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(activeRole['icon'] as IconData,
                                color: roleColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${activeRole['label']} Registration',
                              style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Common Fields ──────────────────────────────
                      _sectionHeader('Personal Information'),
                      const SizedBox(height: 12),
                      _inputField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'John Doe',
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            AppValidators.required(v, field: 'Full name'),
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: AppValidators.email,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '9876543210',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        prefixText: '+91 ',
                        maxLength: 10,
                        validator: AppValidators.phone,
                      ),
                      const SizedBox(height: 14),
                      _passwordField(),

                      // ── Role-specific Fields ───────────────────────
                      if (_selectedRole == 'customer') ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Delivery Details'),
                        const SizedBox(height: 12),
                        _inputField(
                          controller: _addressController,
                          label: 'Default Delivery Address',
                          hint: 'Street, City, State',
                          icon: Icons.home_outlined,
                          maxLines: 2,
                          validator: (v) =>
                              AppValidators.required(v, field: 'Address'),
                        ),
                      ],

                      if (_selectedRole == 'seller') ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Shop / Business Details'),
                        const SizedBox(height: 12),
                        _inputField(
                          controller: _shopNameController,
                          label: 'Shop / Business Name',
                          hint: 'My Awesome Store',
                          icon: Icons.storefront_outlined,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              AppValidators.required(v, field: 'Shop name'),
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _shopCategoryController,
                          label: 'Business Category',
                          hint: 'e.g. Restaurant, Grocery, Electronics',
                          icon: Icons.category_outlined,
                          validator: (v) =>
                              AppValidators.required(v, field: 'Category'),
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _shopAddressController,
                          label: 'Shop Address',
                          hint: 'Full shop address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                          validator: (v) =>
                              AppValidators.required(v, field: 'Shop address'),
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _gstController,
                          label: 'GST Number (Optional)',
                          hint: '22AAAAA0000A1Z5',
                          icon: Icons.receipt_long_outlined,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ],

                      if (_selectedRole == 'delivery_partner') ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Vehicle & Identity'),
                        const SizedBox(height: 12),
                        _inputField(
                          controller: _vehicleTypeController,
                          label: 'Vehicle Type',
                          hint: 'e.g. Bike, Scooter, Car',
                          icon: Icons.two_wheeler_outlined,
                          validator: (v) =>
                              AppValidators.required(v, field: 'Vehicle type'),
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _vehicleNumberController,
                          label: 'Vehicle Registration Number',
                          hint: 'MH12AB1234',
                          icon: Icons.confirmation_number_outlined,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) =>
                              AppValidators.required(v, field: 'Vehicle number'),
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _licenseController,
                          label: 'Driving License Number',
                          hint: 'DL1234567890',
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) =>
                              AppValidators.required(v, field: 'License number'),
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _aadharController,
                          label: 'Aadhar Number',
                          hint: '1234 5678 9012',
                          icon: Icons.fingerprint,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Aadhar is required';
                            if (v.length != 12) return 'Enter valid 12-digit Aadhar';
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Terms ──────────────────────────────────────
                      Text(
                        'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── CTA Button ─────────────────────────────────
                      _buildCTAButton(auth, roleColor),
                      const SizedBox(height: 24),

                      // Sign in link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.login),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFFFF8A00),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
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

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2A9E), Color(0xFF1E40AF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    String? prefixText,
    int? maxLength,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        maxLength: maxLength,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          prefixIcon: Icon(icon, size: 20),
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0A2A9E), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD32F2F)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: AppValidators.password,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0A2A9E), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD32F2F)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCTAButton(AuthProvider auth, Color roleColor) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9900), Color(0xFFFF6B00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _signup,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: auth.isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
