import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart' as db;
import 'package:client_price_comparer/services/product_service.dart';

class ProductRegistrationPage extends StatefulWidget {
  final db.AppDatabase appDatabase;
  final String barcode;
  
  const ProductRegistrationPage({
    super.key, 
    required this.appDatabase, 
    required this.barcode,
  });

  @override
  State<ProductRegistrationPage> createState() => _ProductRegistrationPageState();
}

class _ProductRegistrationPageState extends State<ProductRegistrationPage> {
  late final ProductService _productService;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  // Selected values
  int? _selectedBrandId;
  int? _selectedCategoryId;
  
  // Lists for dropdowns
  List<db.Brand> _brands = [];      // Use db prefix
  List<db.Category> _categories = []; // Use db prefix
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _productService = ProductService(widget.appDatabase);
    _loadDropdownData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Use service instead of direct DB access
      final brands = await _productService.loadBrands();
      final categories = await _productService.loadCategories();
      
      if (mounted) {
        setState(() {
          _brands = brands;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load dropdown data: $e');
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _productService.saveProduct(
        barcode: widget.barcode,
        name: _nameController.text.trim(),
        brandId: _selectedBrandId,
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        imageUrl: _imageUrlController.text.trim().isNotEmpty 
            ? _imageUrlController.text.trim() 
            : null,
      );
      
      if (mounted) {
        // Navigate back to scan page and show success message
        Navigator.pop(context, true); // Pass true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save product: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final String? imagePath = await _productService.navigateToCameraCapture(
        context, 
        widget.barcode,
      );
      
      // Check if widget is still mounted before using context or setState
      if (mounted && imagePath != null) {
        setState(() {
          _imageUrlController.text = imagePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to capture photo: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProduct,
              child: const Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barcode display
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code),
                            const SizedBox(width: 8),
                            Text(
                              'Barcode: ${widget.barcode}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Product name (required)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Brand dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedBrandId,
                      decoration: const InputDecoration(
                        labelText: 'Brand (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('No brand selected'),
                        ),
                        ..._brands.map((brand) => DropdownMenuItem<int>(
                          value: brand.id,
                          child: Text(brand.name),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedBrandId = value),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('No category selected'),
                        ),
                        ..._categories.map((category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Image URL
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Image Path',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true, // Make it read-only since we set it via camera
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _takePicture,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Save Product'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}