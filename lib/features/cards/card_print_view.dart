import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/service_card.dart';

class CardPrintView extends StatelessWidget {
  const CardPrintView({super.key, required this.card});

  final ServiceCard card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طباعة ${card.title}'),
        actions: [
          IconButton(
            onPressed: () => _printCard(context),
            icon: const Icon(Icons.print),
            tooltip: 'طباعة',
          ),
          IconButton(
            onPressed: () => _shareCard(context),
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // شعار الشركة
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi,
                            size: 30,
                            color: Color(0xFF1E3C72),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'NUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'بطاقة إنترنت',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // معلومات البطاقة
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3C72),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _InfoRow('السعة:', card.quota),
                              _InfoRow('السعر:', '${card.price.toStringAsFixed(2)} ر.س'),
                              _InfoRow('اسم المستخدم:', card.username ?? 'غير محدد'),
                              _InfoRow('كلمة المرور:', card.password ?? 'غير محدد'),
                              const SizedBox(height: 12),
                              
                              // QR Code
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: QrImageView(
                                    data: _generateQRData(),
                                    version: QrVersions.auto,
                                    size: 90,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text(
                          'للاستعلام: +967772339262',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // معلومات إضافية
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات البطاقة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow('رقم البطاقة:', card.id),
                    _InfoRow('الحالة:', card.status),
                    if (card.profileName != null) _InfoRow('البروفايل:', card.profileName!),
                    if (card.customerName != null) _InfoRow('العميل:', card.customerName!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareCard(context),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _printCard(context),
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printCard(BuildContext context) {
    // TODO: تنفيذ طباعة البطاقة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: طباعة البطاقة')),
    );
  }

  void _shareCard(BuildContext context) {
    final cardInfo = '''
بطاقة إنترنت NUM
${card.title}

السعة: ${card.quota}
السعر: ${card.price.toStringAsFixed(2)} ر.س
اسم المستخدم: ${card.username ?? 'غير محدد'}
كلمة المرور: ${card.password ?? 'غير محدد'}

للاستعلام: +967772339262
    '''.trim();

    Clipboard.setData(ClipboardData(text: cardInfo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ معلومات البطاقة')),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}