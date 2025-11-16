import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RemoteAccessGuideScreen extends StatefulWidget {
  const RemoteAccessGuideScreen({super.key});

  @override
  State<RemoteAccessGuideScreen> createState() => _RemoteAccessGuideScreenState();
}

class _RemoteAccessGuideScreenState extends State<RemoteAccessGuideScreen> {
  int currentStep = 0;
  
  final List<GuideStep> steps = [
    GuideStep(
      title: '1. تحديد عنوان IP العام',
      description: 'احصل على عنوان IP العام لشبكتك',
      icon: Icons.public,
      color: Colors.blue,
      content: '''
للتحكم في MikroTik من خارج الشبكة، تحتاج لمعرفة عنوان IP العام:

طرق معرفة عنوان IP العام:
• زيارة whatismyip.com
• في MikroTik Terminal: /ip cloud print
• أو استخدم الأمر: /interface print

ملاحظة: إذا كان IP العام متغيراً، ستحتاج لـ Dynamic DNS''',
      commands: [
        '/ip cloud set ddns-enabled=yes',
        '/ip cloud print',
      ],
    ),
    
    GuideStep(
      title: '2. تفعيل خدمة API',
      description: 'تشغيل وإعداد خدمة API في MikroTik',
      icon: Icons.api,
      color: Colors.green,
      content: '''
خدمة API ضرورية للتطبيق للاتصال بـ MikroTik:

1. تفعيل الخدمة على المنفذ 8728
2. السماح بالوصول من أي عنوان (0.0.0.0/0)
3. التأكد من تشغيل الخدمة

بعد تنفيذ الأوامر، تأكد من ظهور "enabled" عند طباعة الخدمات.''',
      commands: [
        '/ip service enable api',
        '/ip service set api port=8728',
        '/ip service set api address=0.0.0.0/0',
        '/ip service print',
      ],
    ),
    
    GuideStep(
      title: '3. فتح المنافذ في Firewall',
      description: 'السماح للمنفذ 8728 في جدار الحماية',
      icon: Icons.security,
      color: Colors.orange,
      content: '''
يجب فتح المنفذ 8728 في Firewall للسماح بالاتصال من الخارج:

1. إضافة قاعدة السماح للمنفذ 8728
2. السماح بالوصول من أي عنوان
3. إضافة تعليق للتمييز

تحذير: كن حذراً عند تعديل Firewall لتجنب قطع الاتصال.''',
      commands: [
        '/ip firewall filter add chain=input protocol=tcp dst-port=8728 action=accept comment="API Remote Access"',
        '/ip firewall filter print where comment="API Remote Access"',
      ],
    ),
    
    GuideStep(
      title: '4. إعداد Port Forwarding',
      description: 'توجيه المنفذ للوصول من خارج الشبكة',
      icon: Icons.router,
      color: Colors.purple,
      content: '''
إذا كان MikroTik خلف راوتر آخر، تحتاج لـ Port Forwarding:

**الحالة 1: MikroTik هو الراوتر الرئيسي**
لا تحتاج Port Forwarding - فقط Firewall rules

**الحالة 2: MikroTik خلف راوتر آخر**
أعد توجيه المنفذ 8728 من الراوتر الخارجي إلى MikroTik

في بعض الحالات قد تحتاج DSTNAT rule في MikroTik نفسه.''',
      commands: [
        '# إذا كان MikroTik خلف NAT:',
        '/ip firewall nat add chain=dstnat protocol=tcp dst-port=8728 action=dst-nat to-addresses=192.168.1.1',
        '# غيّر 192.168.1.1 بعنوان MikroTik المحلي',
      ],
    ),
    
    GuideStep(
      title: '5. إنشاء مستخدم للتحكم عن بُعد',
      description: 'إنشاء مستخدم مخصص بصلاحيات آمنة',
      icon: Icons.person_add,
      color: Colors.indigo,
      content: '''
من الأفضل إنشاء مستخدم منفصل للتحكم عن بُعد:

1. اختر كلمة مرور قوية
2. حدد عنوان IP إذا كنت تريد تقييد الوصول
3. استخدم مجموعة "full" للصلاحيات الكاملة

يمكنك تقييد الوصول بعنوان IP محدد لأمان إضافي.''',
      commands: [
        '/user add name=remote-user password=StrongPassword123 group=full',
        '/user set remote-user address=0.0.0.0/0 comment="Remote API Access"',
        '# للتقييد بعنوان معين:',
        '# /user set remote-user address=YOUR_IP_ADDRESS',
      ],
    ),
    
    GuideStep(
      title: '6. اختبار الاتصال',
      description: 'التأكد من عمل الاتصال من خارج الشبكة',
      icon: Icons.wifi_tethering,
      color: Colors.teal,
      content: '''
اختبر الاتصال من خارج الشبكة:

**الاختبار الأولي:**
• استخدم بيانات الهاتف المحمول
• جرب الاتصال من شبكة مختلفة

**في التطبيق:**
• أدخل العنوان العام (أو Dynamic DNS)
• المنفذ: 8728
• بيانات المستخدم الجديد

**إذا فشل الاتصال:**
استخدم شاشة "تشخيص مشاكل الاتصال" في التطبيق.''',
      commands: [
        '# اختبار بسيط من Terminal/CMD:',
        'telnet YOUR_PUBLIC_IP 8728',
        '# يجب أن ترى رد من MikroTik API',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل التحكم عن بُعد'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(steps.length, (index) {
                final isActive = index == currentStep;
                final isCompleted = index < currentStep;
                
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < steps.length - 1 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive 
                          ? theme.primaryColor 
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Step content
          Expanded(
            child: PageView.builder(
              onPageChanged: (index) => setState(() => currentStep = index),
              itemCount: steps.length,
              itemBuilder: (context, index) => _buildStepContent(steps[index]),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: currentStep > 0 
                      ? () => setState(() => currentStep--) 
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('السابق'),
                ),
                Text(
                  '${currentStep + 1} من ${steps.length}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: currentStep < steps.length - 1 
                      ? () => setState(() => currentStep++) 
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(currentStep < steps.length - 1 ? 'التالي' : 'انتهى'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(GuideStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  step.color.withOpacity(0.8),
                  step.color.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(step.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Step content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
                
                if (step.commands.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'أوامر MikroTik:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _copyAllCommands(step.commands),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('نسخ الكل'),
                        style: TextButton.styleFrom(
                          foregroundColor: step.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: step.color.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: step.commands.map((command) => 
                        _buildCommandItem(command, step.color)
                      ).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandItem(String command, Color color) {
    final isComment = command.trim().startsWith('#');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              command,
              style: TextStyle(
                fontSize: 14,
                color: isComment 
                    ? Colors.grey.shade400 
                    : Colors.green.shade300,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
          if (!isComment)
            IconButton(
              onPressed: () => _copyCommand(command),
              icon: Icon(
                Icons.copy,
                size: 16,
                color: color.withOpacity(0.7),
              ),
              tooltip: 'نسخ',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  void _copyCommand(String command) {
    Clipboard.setData(ClipboardData(text: command));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('تم نسخ الأمر'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _copyAllCommands(List<String> commands) {
    final allCommands = commands
        .where((cmd) => !cmd.trim().startsWith('#'))
        .join('\n');
    
    Clipboard.setData(ClipboardData(text: allCommands));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('تم نسخ ${commands.length} أمر'),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class GuideStep {
  final String title;
  final String description;
  final String content;
  final List<String> commands;
  final IconData icon;
  final Color color;

  GuideStep({
    required this.title,
    required this.description,
    required this.content,
    required this.commands,
    required this.icon,
    required this.color,
  });
}