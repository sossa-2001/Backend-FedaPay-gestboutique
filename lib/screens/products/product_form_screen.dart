import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/responsive.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
    _barcodeCtrl = TextEditingController(text: widget.product?.barcode ?? '');
    _priceCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.price.toString() : '',
    );
    _costCtrl = TextEditingController(
      text: widget.product?.costPrice?.toString() ?? '',
    );
    _stockCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.stockQuantity.toString()
          : '',
    );
    _minStockCtrl = TextEditingController(
      text: widget.product?.minStock?.toString() ?? '',
    );
    _selectedCategoryId = widget.product?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product != null ? 'Modifier le produit' : 'Nouveau produit',
        ),
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(labelText: 'Code-barres'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prix de vente *',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prix d\'achat',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock initial *',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock minimum',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    widget.product != null ? 'Enregistrer' : 'Créer le produit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductProvider>();
    final product = widget.product ?? Product();
    product.name = _nameCtrl.text;
    product.description = _descCtrl.text.isNotEmpty ? _descCtrl.text : null;
    product.barcode = _barcodeCtrl.text.isNotEmpty ? _barcodeCtrl.text : null;
    product.price = double.tryParse(_priceCtrl.text) ?? 0;
    product.costPrice = double.tryParse(_costCtrl.text);
    product.stockQuantity = double.tryParse(_stockCtrl.text) ?? 0;
    product.minStock = double.tryParse(_minStockCtrl.text);
    product.categoryId = _selectedCategoryId;

    if (widget.product != null) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }
}
