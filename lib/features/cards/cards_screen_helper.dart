import 'package:flutter/material.dart';

import '../../data/models/service_card.dart';
import 'add_card_dialog.dart';
import 'card_pdf_generator_enhanced.dart';
import 'card_print_view.dart';
import 'cards_print_manager.dart';
import 'pdf_files_manager_screen.dart';

mixin CardsScreenHelper {
  void showAddCardDialog(BuildContext context, repository, VoidCallback onCardAdded) {
    showDialog(
      context: context,
      builder: (context) => AddCardDialog(
        repository: repository,
        onCardAdded: onCardAdded,
      ),
    );
  }

  void showFinishedCards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('البطاقات المنتهية')),
          body: const Center(child: Text('قريباً: عرض البطاقات المنتهية')),
        ),
      ),
    );
  }

  void handleCardAction(BuildContext context, String action, ServiceCard card, repository, VoidCallback onCardAdded) {
    switch (action) {
      case 'print':
        printCard(context, card);
        break;
      case 'edit':
        editCard(context, card, repository, onCardAdded);
        break;
      case 'delete':
        deleteCard(context, card, onCardAdded);
        break;
    }
  }

  void printCard(BuildContext context, ServiceCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardPrintView(card: card),
      ),
    );
  }

  void openPrintManager(BuildContext context, repository) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardsPrintManager(repository: repository),
      ),
    );
  }

  void openFilesManager(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PdfFilesManagerScreen(),
      ),
    );
  }

  void printCardsWithTemplate(BuildContext context, List<ServiceCard> cards, CardTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خيارات الطباعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('معاينة'),
              onTap: () {
                Navigator.pop(context);
                CardPdfGeneratorEnhanced.previewCards(cards, template: template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('طباعة'),
              onTap: () {
                Navigator.pop(context);
                CardPdfGeneratorEnhanced.printCards(cards, template: template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('حفظ PDF'),
              onTap: () async {
                Navigator.pop(context);
                final path = await CardPdfGeneratorEnhanced.saveCardsPdf(
                  cards,
                  template: template,
                  customName: 'cards_${DateTime.now().millisecondsSinceEpoch}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حفظ الملف في: $path'),
                    action: SnackBarAction(
                      label: 'عرض الملفات',
                      onPressed: () => openFilesManager(context),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة'),
              onTap: () {
                Navigator.pop(context);
                CardPdfGeneratorEnhanced.shareCards(cards, template: template);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void editCard(BuildContext context, ServiceCard card, repository, VoidCallback onCardAdded) {
    showDialog(
      context: context,
      builder: (context) => AddCardDialog(
        repository: repository,
        card: card,
        onCardAdded: onCardAdded,
      ),
    );
  }

  void deleteCard(BuildContext context, ServiceCard card, VoidCallback onCardAdded) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف بطاقة "${card.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف البطاقة')),
              );
              onCardAdded();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void manageCard(BuildContext context, ServiceCard card, repository, VoidCallback onCardAdded) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('طباعة البطاقة'),
              onTap: () {
                Navigator.pop(context);
                printCard(context, card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('طباعة بقالب مختلف'),
              onTap: () {
                Navigator.pop(context);
                _showTemplateSelector(context, [card]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل البطاقة'),
              onTap: () {
                Navigator.pop(context);
                editCard(context, card, repository, onCardAdded);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('تفاصيل البطاقة'),
              onTap: () {
                Navigator.pop(context);
                showCardDetails(context, card);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelector(BuildContext context, List<ServiceCard> cards) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر قالب البطاقة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: CardTemplate.values.map((template) {
              return ListTile(
                title: Text(template.displayName),
                subtitle: Text(_getTemplateDescription(template)),
                leading: Icon(_getTemplateIcon(template)),
                onTap: () {
                  Navigator.pop(context);
                  printCardsWithTemplate(context, cards, template);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  String _getTemplateDescription(CardTemplate template) {
    switch (template) {
      case CardTemplate.classic:
        return 'التصميم الاعتيادي للبطاقات';
      case CardTemplate.modern:
        return 'تصميم عصري بألوان متدرجة';
      case CardTemplate.minimal:
        return 'تصميم بسيط ونظيف';
      case CardTemplate.premium:
        return 'تصميم مميز بتفاصيل إضافية';
    }
  }

  IconData _getTemplateIcon(CardTemplate template) {
    switch (template) {
      case CardTemplate.classic:
        return Icons.credit_card;
      case CardTemplate.modern:
        return Icons.style;
      case CardTemplate.minimal:
        return Icons.minimize;
      case CardTemplate.premium:
        return Icons.star;
    }

  void showCardDetails(BuildContext context, ServiceCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل ${card.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم البطاقة: ${card.id}'),
            Text('السعة: ${card.quota}'),
            Text('السعر: ${card.price.toStringAsFixed(2)} ر.س'),
            Text('اسم المستخدم: ${card.username ?? 'غير محدد'}'),
            Text('كلمة المرور: ${card.password ?? 'غير محدد'}'),
            Text('الحالة: ${card.status}'),
            if (card.profileName != null) Text('البروفايل: ${card.profileName}'),
            if (card.customerName != null) Text('العميل: ${card.customerName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              printCard(context, card);
            },
            child: const Text('طباعة'),
          ),
        ],
      ),
    );
  }
}