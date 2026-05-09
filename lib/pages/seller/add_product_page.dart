import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isVeg = true;
  bool _isAvailable = true;
  bool _isSaving = false;
  String _selectedCategory = 'Food';
  String? _shopId;
  XFile? _imageFile;

  final List<String> _categories = [
    'Food', 'Grocery', 'Pharmacy', 'Clothing',
    'Electronics', 'Beverages', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchShopId();
  }

  Future<void> _fetchShopId() async {
    final auth = context.read<AuthProvider>();
    try {
      final resp = await _supabase
          .from('shops')
          .select('id')
          .eq('seller_id', auth.currentUserId ?? '')
          .single();
      setState(() => _shopId = resp['id']);
    } catch (e) {
      debugPrint('Shop fetch error: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imageFile = file);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No shop found. Create a shop first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _supabase.from('products').insert({
        'shop_id': _shopId,
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'is_veg': _isVeg,
        'is_available': _isAvailable,
        'images': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _imageFile != null
                            ? Icons.check_circle
                            : Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _imageFile != null
                            ? 'Image selected ✓'
                            : 'Tap to add product image',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _card(
                children: [
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => AppValidators.required(v, field: 'Product name'),
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'e.g., Chicken Biryani',
                      prefixIcon: Icon(Icons.fastfood_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: AppValidators.price,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹)',
                      hintText: '199',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Describe your product...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _card(
                children: [
                  const Text('Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _card(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vegetarian',
                        style: TextStyle(fontFamily: 'Poppins')),
                    subtitle: Text(
                      _isVeg ? 'Marked as veg 🟢' : 'Marked as non-veg 🔴',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isVeg,
                    activeThumbColor: AppColors.vegGreen,
                    onChanged: (v) => setState(() => _isVeg = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available',
                        style: TextStyle(fontFamily: 'Poppins')),
                    subtitle: Text(
                      _isAvailable
                          ? 'Visible to customers'
                          : 'Hidden from customers',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isAvailable,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Add Product',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(children: children),
    );
  }
}
