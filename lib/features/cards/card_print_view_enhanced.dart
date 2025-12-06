import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/service_card.dart';

class CardPrintViewEnhanced extends StatelessWidget {
  const CardPrintViewEnhanced({super.key, required this.card});

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
            // البطاقة الرئيسية
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
                        // رأس البطاقة
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'NUM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'بطاقة إنترنت',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi,
                                size: 25,
                                color: Color(0xFF1E3C72),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // معلومات البطاقة
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                card.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3C72),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _InfoColumn('السعة', card.quota),
                                  _InfoColumn('السعر', '${card.price.toStringAsFixed(0)} ر.س'),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              // بيانات الدخول
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _InfoColumn('المستخدم', card.username ?? 'user${card.id}'),
                                  _InfoColumn('المرور', card.password ?? 'pass${card.id}'),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // QR Code
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: QrImageView(
                                  data: _generateQRData(),
                                  version: QrVersions.auto,
                                  size: 100,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // معلومات الاتصال
                        const Text(
                          'للاستعلام والدعم الفني',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          '+967772339262',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                      'تفاصيل البطاقة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow('رقم البطاقة:', card.id),
                    _InfoRow('نوع البطاقة:', card.title),
                    _InfoRow('السعة المتاحة:', card.quota),
                    _InfoRow('قيمة البطاقة:', '${card.price.toStringAsFixed(2)} ر.س'),
                    _InfoRow('الحالة:', card.status),
                    if (card.profileName != null) _InfoRow('البروفايل:', card.profileName!),
                    if (card.customerName != null) _InfoRow('العميل:', card.customerName!),
                    if (card.createdAt != null) 
                      _InfoRow('تاريخ الإنشاء:', '${card.createdAt!.day}/${card.createdAt!.month}/${card.createdAt!.year}'),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'تعليمات الاستخدام:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          SizedBox(height: 8),
                          Text('1. اتصل بشبكة WiFi', style: TextStyle(fontSize: 12)),
                          Text('2. أدخل اسم المستخدم وكلمة المرور', style: TextStyle(fontSize: 12)),
                          Text('3. ستتم إعادة توجيهك لصفحة تسجيل الدخول', style: TextStyle(fontSize: 12)),
                          Text('4. استمتع بالإنترنت!', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
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

  String _generateQRData() {
    // إنشاء بيانات QR Code للبطاقة بتنسيق JSON
    return '''{
  "id": "${card.id}",
  "title": "${card.title}",
  "username": "${card.username ?? 'user${card.id}'}",
  "password": "${card.password ?? 'pass${card.id}'}",
  "quota": "${card.quota}",
  "price": ${card.price},
  "status": "${card.status}"
}''';
  }

  void _printCard(BuildContext context) {
    // TODO: تنفيذ طباعة البطاقة باستخدام printing package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قريباً: طباعة البطاقة مع QR Code'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCard(BuildContext context) {
    final cardInfo = '''
بطاقة إنترنت NUM
================

نوع البطاقة: ${card.title}
رقم البطاقة: ${card.id}
السعة: ${card.quota}
السعر: ${card.price.toStringAsFixed(2)} ر.س

بيانات الدخول:
اسم المستخدم: ${card.username ?? 'user${card.id}'}
كلمة المرور: ${card.password ?? 'pass${card.id}'}

الحالة: ${card.status}

للاستعلام والدعم الفني: +967772339262

تم إنشاؤها بواسطة نظام NUM
    '''.trim();

    Clipboard.setData(ClipboardData(text: cardInfo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ معلومات البطاقة إلى الحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3C72),
          ),
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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