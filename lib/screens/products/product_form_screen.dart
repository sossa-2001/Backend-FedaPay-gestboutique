import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/responsive.dart';
import '../../theme/app_colors.dart';

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
  late final TextEditingController _manualDiscountCtrl;
  int? _selectedCategoryId;
  final List<_TierEntry> _tiers = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toString() : '');
    _costCtrl = TextEditingController(text: p?.costPrice?.toString() ?? '');
    _stockCtrl = TextEditingController(text: p != null ? p.stockQuantity.toString() : '');
    _minStockCtrl = TextEditingController(text: p?.minStock?.toString() ?? '');
    _manualDiscountCtrl = TextEditingController(text: p?.manualDiscountMax?.toString() ?? '');
    _selectedCategoryId = p?.categoryId;
    if (p != null) {
      for (final t in p.discountTiers) {
        _tiers.add(_TierEntry(
          quantityCtrl: TextEditingController(text: t.minQuantity.toString()),
          discountCtrl: TextEditingController(text: t.discountAmount.toString()),
        ));
      }
    }
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
    _manualDiscountCtrl.dispose();
    for (final t in _tiers) {
      t.quantityCtrl.dispose();
      t.discountCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Modifier le produit' : 'Nouveau produit'),
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
                decoration: const InputDecoration(labelText: 'Nom du produit *'),
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
                      decoration: const InputDecoration(labelText: 'Prix de vente *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      decoration: const InputDecoration(labelText: 'Prix d\'achat'),
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
                      decoration: const InputDecoration(labelText: 'Stock initial *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock minimum'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDiscountSection(context),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.product != null ? 'Enregistrer' : 'Créer le produit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Réductions automatiques (par quantité)',
            style: TextStyle(fontSize: context.fontSizeMd, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Remise en FCFA par unité selon le nombre acheté',
            style: TextStyle(fontSize: context.fontSizeSm, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._tiers.asMap().entries.map((entry) => _buildTierRow(entry.key)),
          if (_tiers.isNotEmpty) const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addTier,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter un palier'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Réduction manuelle (vendeur)',
            style: TextStyle(fontSize: context.fontSizeMd, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Montant max qu\'un vendeur peut déduire manuellement (ex: 500 FCFA)',
            style: TextStyle(fontSize: context.fontSizeSm, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _manualDiscountCtrl,
            decoration: const InputDecoration(
              labelText: 'Remise manuelle max (FCFA)',
              hintText: 'Laisser vide pour désactiver',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(int index) {
    final tier = _tiers[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: tier.quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'À partir de',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('×', style: TextStyle(color: AppColors.textSecondary, fontSize: context.fontSizeMd)),
          ),
          Expanded(
            child: TextFormField(
              controller: tier.discountCtrl,
              decoration: const InputDecoration(
                labelText: 'Remise FCFA',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
            onPressed: () => setState(() => _tiers.removeAt(index)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _addTier() {
    setState(() {
      _tiers.add(_TierEntry(
        quantityCtrl: TextEditingController(),
        discountCtrl: TextEditingController(),
      ));
    });
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

    product.discountTiers = _tiers
        .where((t) =>
            t.quantityCtrl.text.isNotEmpty && t.discountCtrl.text.isNotEmpty)
        .map((t) => DiscountTier(
              minQuantity: int.tryParse(t.quantityCtrl.text) ?? 0,
              discountAmount: double.tryParse(t.discountCtrl.text) ?? 0,
            ))
        .where((t) => t.minQuantity > 0 && t.discountAmount > 0)
        .toList();

    final manualMax = double.tryParse(_manualDiscountCtrl.text);
    product.manualDiscountMax = manualMax != null && manualMax > 0 ? manualMax : null;

    if (widget.product != null) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _TierEntry {
  final TextEditingController quantityCtrl;
  final TextEditingController discountCtrl;
  _TierEntry({required this.quantityCtrl, required this.discountCtrl});
}
