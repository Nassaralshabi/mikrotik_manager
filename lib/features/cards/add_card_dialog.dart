import 'package:flutter/material.dart';

import '../../data/models/service_card.dart';
import '../../data/repositories/backend_repository.dart';

class AddCardDialog extends StatefulWidget {
  const AddCardDialog({
    super.key,
    required this.repository,
    this.card,
    required this.onCardAdded,
  });

  final BackendRepository repository;
  final ServiceCard? card;
  final VoidCallback onCardAdded;

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _quotaController;
  late final TextEditingController _priceController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  String _selectedProfile = 'default';
  String _selectedCustomer = 'default';
  int _cardCount = 1;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?.title ?? '');
    _quotaController = TextEditingController(text: widget.card?.quota ?? '');
    _priceController = TextEditingController(text: widget.card?.price.toString() ?? '');
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quotaController.dispose();
    _priceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.card != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'تعديل البطاقة' : 'إضافة بطاقات جديدة'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'عدد البطاقات: $_cardCount',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _cardCount > 1 ? () => setState(() => _cardCount--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _cardCount++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'اسم البطاقة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'أدخل اسم البطاقة' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quotaController,
                        decoration: const InputDecoration(
                          labelText: 'السعة (مثل: 1GB)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'أدخل السعة' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر (ر.س)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) return 'أدخل السعر';
                          if (double.tryParse(value!) == null) return 'أدخل رقم صحيح';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProfile,
                  decoration: const InputDecoration(
                    labelText: 'البروفايل',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('البروفايل الافتراضي')),
                    DropdownMenuItem(value: 'premium', child: Text('البروفايل المميز')),
                    DropdownMenuItem(value: 'basic', child: Text('البروفايل الأساسي')),
                  ],
                  onChanged: (value) => setState(() => _selectedProfile = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'العميل',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('العميل الافتراضي')),
                    DropdownMenuItem(value: 'retail', child: Text('عميل تجزئة')),
                    DropdownMenuItem(value: 'wholesale', child: Text('عميل جملة')),
                  ],
                  onChanged: (value) => setState(() => _selectedCustomer = value!),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saveCard,
          child: Text(isEditing ? 'تحديث' : 'إنشاء البطاقات'),
        ),
      ],
    );
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;

    final cardData = {
      'title': _titleController.text.trim(),
      'quota': _quotaController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'profile': _selectedProfile,
      'customer': _selectedCustomer,
      'count': _cardCount,
    };

    if (widget.card != null) {
      cardData['username'] = _usernameController.text.trim();
      cardData['password'] = _passwordController.text.trim();
    }

    // TODO: تنفيذ إضافة البطاقات عبر API
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.card != null 
            ? 'تم تحديث البطاقة بنجاح'
            : 'تم إنشاء $_cardCount بطاقة بنجاح',
        ),
      ),
    );
    widget.onCardAdded();
  }
}