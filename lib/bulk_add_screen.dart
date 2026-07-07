// bulk_add_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'bulk_add_isolate.dart';
import 'saved_files_screen.dart';
import 'card_list_screen.dart';
import 'mqtt_service.dart';
import 'pdf_templates_screen.dart';
import 'pdf_generator.dart';
import 'snackbar_helpers.dart';
import 'shared/widgets/save_location_selector.dart';
import 'core/services/card_save_service.dart';

class BulkAddScreen extends StatefulWidget {
  final List<Map<String, dynamic>> profiles;
  final bool isVersion7OrNewer;
  final String username;

  const BulkAddScreen({
    super.key,
    required this.profiles,
    required this.isVersion7OrNewer,
    required this.username,
  });

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _generationStatusText = '';
  String? _addCardsJobId;
  Timer? _addCardsTimer;
  bool _isJobAcknowledged = false;

  final _prefixController = TextEditingController();
  final _lengthController = TextEditingController(text: '8');
  final _countController = TextEditingController(text: '10');
  final _sharedUsersController = TextEditingController(text: '1');

  String? _selectedProfile;
  String _charType = 'numbers';
  String _cardType = 'username_only';
  bool _linkPasswordToFirstUser = false;
  List<SaveLocation> _saveLocations = [SaveLocation.mikrotikDevice];
  int _sharedUsers = 1;
  List<String> _sharedUsersList = [];
  
  // القوالب والقالب المختار
  List<PdfTemplate> _templates = [];
  PdfTemplate? _selectedTemplate;

  late MqttService _mqttService;
  StreamSubscription? _mqttSubscription;
  bool _isNetworkLinked = false;
  Map<String, dynamic> _linkedData = {};

  final String telegramBotToken = '';
  final String telegramChatId = '';

  @override
  void initState() {
    super.initState();
    _checkLinkStatus();
    _loadTemplates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mqttService = Provider.of<MqttService>(context, listen: false);
    _setupMqttListener();
  }

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = prefs.getStringList('pdf_templates') ?? const [];
    // بناء القائمة بـ for loop بدلاً من map.toList()
    final List<PdfTemplate> loaded = [
      for (final jsonString in templatesJson)
        PdfTemplate.fromJson(jsonDecode(jsonString) as Map<String, dynamic>),
    ];
    if (mounted) {
      setState(() {
        _templates = loaded;
      });
    }
  }

  Future<void> _checkLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLinked = prefs.getBool('is_network_linked') ?? false;
    if (isLinked) {
      final dataString = prefs.getString('qahtani_linked_data');
      if (dataString != null) {
        setState(() {
          _isNetworkLinked = true;
          _linkedData = jsonDecode(dataString);
        });
      }
    }
  }

  void _setupMqttListener() {
    _mqttSubscription?.cancel();
    _mqttSubscription = _mqttService.messages.listen((message) {
      if (!mounted) return;
      
      final jobId = message['job_id'];
      if (_addCardsJobId == null || jobId != _addCardsJobId) return;

      final status = message['status'];

      switch(status) {
        case 'acknowledged':
          _addCardsTimer?.cancel();
          setState(() {
            _isJobAcknowledged = true;
          });
          Navigator.of(context, rootNavigator: true).pop();
          _showWaitingDialog("تم استلام الطلب، جاري الإضافة إلى م/نصار الشعبي...");
          break;
        
        case 'job_status_response':
           final jobStatus = message['job_status'];
           if (jobStatus == 'not_found') {
             _addCardsTimer?.cancel();
             Navigator.of(context, rootNavigator: true).pop(); 
            _showErrorDialog("فشل إرسال الطلب، الرجاء المحاولة مرة أخرى.");
           }
           break;

        case 'cards_added_success':
          _addCardsTimer?.cancel();
          Navigator.of(context, rootNavigator: true).pop(); 
          showSuccessSnackBar(context, message['message'] ?? 'تمت العملية بنجاح.');
          break;

        case 'error':
          _addCardsTimer?.cancel();
          Navigator.of(context, rootNavigator: true).pop(); 
          _showErrorDialog(message['message'] ?? 'حدث خطأ.');
          break;
      }
    });
  }

  Future<void> _sendTelegramMessage(String message) async {
    final dio = Dio();
    final url = 'https://api.telegram.org/bot$telegramBotToken/sendMessage';
    try {
      await dio.post(url, data: {'chat_id': telegramChatId, 'text': message});
    } catch (e) {
      // print("Failed to send Telegram message: $e");
    }
  }

  Future<void> _generateUsers() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
      _generationStatusText = 'جاري التحضير...';
    });

    final receivePort = ReceivePort();
    final isolateData = BulkAddIsolateData(
      sendPort: receivePort.sendPort,
      count: int.parse(_countController.text),
      length: int.parse(_lengthController.text),
      prefix: _prefixController.text.trim(),
      sharedUsers: _sharedUsersController.text.trim(),
      selectedProfile: _selectedProfile,
      charType: _charType,
      cardType: _cardType,
      linkPasswordToFirstUser: _linkPasswordToFirstUser,
      isVersion7OrNewer: widget.isVersion7OrNewer,
      rootIsolateToken: RootIsolateToken.instance!,
      customer: widget.username,
    );

    final isolate = await Isolate.spawn(bulkAddIsolate, isolateData);

    StreamSubscription? subscription;
    void cleanup() {
      subscription?.cancel();
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
    }

    subscription = receivePort.listen((message) {
      if (!mounted) return;

      final type = message['type'];
      if (type == 'progress') {
        setState(() {
          _generationProgress = message['progress'];
          _generationStatusText = message['status'];
        });
      } else if (type == 'success') {
        final newlyCreatedUsers = (message['users'] as List).cast<Map<String, dynamic>>();
        final successCount = message['count'] as int;
        final address = message['address'] as String;

        final String notificationMessage =
            "تم إضافة $successCount كرت جديد بنجاح!\n"
            "IP: $address\n"
            "الفئة: $_selectedProfile";
        _sendTelegramMessage(notificationMessage);

        if (mounted) setState(() { _isGenerating = false; });

        if (newlyCreatedUsers.isNotEmpty) {
          // بناء القائمة بـ for loop بدلاً من map.toList()
          final List<Map<String, String>> simplifiedUsers = [
            for (final e in newlyCreatedUsers)
              {
                'username': e['username'] as String,
                'password': e['password'] as String,
              },
          ];
          // حفظ الكروت في الوجهات الإضافية المختارة
          _saveCardsToAdditionalLocations(simplifiedUsers);

          _showSuccessDialog(simplifiedUsers);
        }

        cleanup();
      } else if (type == 'error') {
        final errorMessage = message['message'] as String;
        final successCount = message['count'] as int;
        _showErrorDialog('فشلت العملية بعد إنشاء $successCount كرت: $errorMessage');
        if (mounted) setState(() { _isGenerating = false; });
        cleanup();
      }
    });
  }

  void _showSuccessDialog(List<Map<String, String>> users) async {
      // بناء القائمة بـ for loop بدلاً من map.toList()
      final List<String> userListForFile = [
        for (final user in users)
          _cardType == 'username_only'
              ? user['username']!
              : 'username: ${user['username']}, password: ${user['password']}',
      ];

      final String fileContent = userListForFile.join('\n');

      final directory = await getApplicationDocumentsDirectory();
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/new_cards_$timestamp.txt';
      final file = File(filePath);
      await file.writeAsString(fileContent);

      final prefs = await SharedPreferences.getInstance();
      final savedFile = SavedFile(
          path: filePath,
          profileName: _selectedProfile!,
          userCount: users.length,
          date: DateTime.now());
      final existingFiles = <String>[...prefs.getStringList('saved_files') ?? const []];
      existingFiles.add(jsonEncode(savedFile.toJson()));
      await prefs.setStringList('saved_files', existingFiles);

      // استخدام القالب المختار من المستخدم، أو البحث عن قالب مطابق للـ profile
      PdfTemplate? relevantTemplate = _selectedTemplate;
      if (relevantTemplate == null) {
        final templatesJson = prefs.getStringList('pdf_templates') ?? const [];
        try {
          final templateJson = templatesJson.firstWhere(
            (json) => PdfTemplate.fromJson(jsonDecode(json) as Map<String, dynamic>).profileName == _selectedProfile,
          );
          relevantTemplate = PdfTemplate.fromJson(jsonDecode(templateJson) as Map<String, dynamic>);
        } catch (e) {
          // لم يوجد قالب مطابق — سنظهر رسالة للمستخدم
          debugPrint('No PDF template found for profile "$_selectedProfile": $e');
        }
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(
                child: Text('عملية ناجحة')),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Center(child: Text('تم إنشاء ${users.length} كرت بنجاح!')) ,
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('عرض الكروت'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) =>
                                CardListScreen(cardList: userListForFile)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة كملف نصي'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await SharePlus.instance.share(ShareParams(
                        files: [XFile(filePath)],
                        text: 'New MikroTik Users',
                      ));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  ),

                  if (relevantTemplate != null) ...[
                    const SizedBox(height: 8),
                     ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('مشاركة PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                        onPressed: () {
                          Navigator.of(context).pop();
                          // بناء القائمة بـ for loop بدلاً من map.toList()
                          final List<String> usernamesOnly = [
                            for (final u in users) u['username']!,
                          ];
                          PdfGenerator.sharePdf(
                            context,
                            cardUsernames: usernamesOnly,
                            template: relevantTemplate!,
                            category: _selectedProfile ?? 'general',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('حفظ PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // بناء القائمة بـ for loop بدلاً من map.toList()
                          final List<String> usernamesOnly = [
                            for (final u in users) u['username']!,
                          ];
                          // استخدام savePdf لحفظ الملف محلياً
                          await PdfGenerator.savePdf(
                            context,
                            cardUsernames: usernamesOnly,
                            template: relevantTemplate!,
                            category: _selectedProfile ?? 'general',
                          );
                        },
                      ),
                  ] else ...[
                    // لا يوجد قالب PDF مطابق — اعرض رسالة تنبيه
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لا يوجد قالب PDF للفئة "$_selectedProfile". '
                              'يمكنك إنشاء قالب من شاشة "إدارة قوالب PDF".',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isNetworkLinked) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_to_queue),
                      label: const Text('إضافة لـ م/نصار الشعبي'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showAddCardsToQahtaniDialog(users);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                    ),
                  ],
                  TextButton(child: const Text('إغلاق'), onPressed: () => Navigator.of(context).pop())
                ],
              ),
            ),
          );
        },
      );
  }

  void _showAddCardsToQahtaniDialog(List<Map<String, String>> cards) {
    String? selectedUnitId;
    final units = (_linkedData['network_details']?['units'] as List?) ?? const [];

    // بناء عناصر القائمة المنسدلة بـ for loop بدلاً من map.toList()
    final List<DropdownMenuItem<String>> unitItems = [
      for (final unit in units)
        DropdownMenuItem<String>(
          value: unit['id'],
          child: Text(unit['name'],
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        )
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر فئة م/نصار الشعبي'),
          content: DropdownButtonFormField<String>(
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            dropdownColor: Colors.white,
            hint: const Text('اختر الفئة', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            items: unitItems,
            onChanged: (value) {
              selectedUnitId = value;
            },
            validator: (value) => value == null ? 'الرجاء اختيار فئة' : null,
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('تأكيد وإضافة'),
              onPressed: () {
                if (selectedUnitId != null) {
                  Navigator.of(context).pop();
                  _sendCardsToQahtani(cards, selectedUnitId!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _sendCardsToQahtani(List<Map<String, String>> cards, String selectedUnitId) {
      _showWaitingDialog("جاري إرسال الكروت...");

      setState(() {
        _addCardsJobId = _mqttService.generateUniqueId();
        _isJobAcknowledged = false;
      });

      _addCardsTimer?.cancel();
      _addCardsTimer = Timer(const Duration(seconds: 10), _checkAddCardsStatus);

      // بناء القائمة بـ for loop بدلاً من map.toList()
      final List<String> cardUsernamesOnly = [
        for (final cardMap in cards) cardMap['username']!,
      ];
      final String cardsAsString = cardUsernamesOnly.join('\n');

      _mqttService.publish({
        'command': 'add_wifi_cards',
        'network_id': _linkedData['network_details']?['network_id'],
        'unit_id': selectedUnitId,
        'cards': cardsAsString,
        'job_id': _addCardsJobId,
      });
  }

  void _checkAddCardsStatus() {
    if (!mounted) return;

    if (_isJobAcknowledged) {
       // print("⏰ [إضافة كروت] الطلب تم استلامه، ننتظر...");
       return;
    }

    // print("⏰ [إضافة كروت] لم يتم استلام تأكيد، جاري فحص حالة الطلب...");
    _mqttService.publish({
      'command': 'get_job_status',
      'job_id': _addCardsJobId,
    });
  }


  void _showWaitingDialog(String message) {
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ]),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showErrorSnackBar(context, message);
  }


  /// يحفظ الكروت في الوجهات الإضافية بعد الإنشاء على MikroTik
  Future<void> _saveCardsToAdditionalLocations(List<Map<String, String>> cards) async {
    for (final location in _saveLocations) {
      if (location == SaveLocation.mikrotikDevice) continue;
      
      for (final card in cards) {
        await CardSaveService.instance.saveCard(
          card: CardSaveData(
            username: card['username'] as String? ?? '',
            password: card['password'] as String?,
            profileName: _selectedProfile,
            sharedUsers: int.tryParse(_sharedUsersController.text) ?? 1,
          ),
          location: location,
          context: context,
        );
      }
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _lengthController.dispose();
    _countController.dispose();
    _sharedUsersController.dispose();
    _mqttSubscription?.cancel();
    _addCardsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // بناء عناصر القوائم المنسدلة بـ for loop بدلاً من map.toList()
    final List<DropdownMenuItem<String>> profileItems = [
      for (final p in widget.profiles)
        DropdownMenuItem<String>(
            value: p['name'] as String,
            child: Text(p['name'] as String,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold))),
    ];
    final List<DropdownMenuItem<String>> templateItems = [
      for (final template in _templates)
        DropdownMenuItem<String>(
            value: template.profileName, child: Text(template.profileName)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة كروت جماعية'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: _isGenerating
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_generationStatusText, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: _generationProgress,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 10),
                  Text('${(_generationProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          )
        : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                        labelText: 'بادئة (اختياري)',
                        border: OutlineInputBorder()),
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                            controller: _lengthController,
                            decoration: const InputDecoration(
                                labelText: 'الطول', border: OutlineInputBorder()),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'مطلوب' : null)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextFormField(
                            controller: _countController,
                            decoration: const InputDecoration(
                                labelText: 'العدد', border: OutlineInputBorder()),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'مطلوب' : null)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProfile,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                      labelText: 'الفئة (البروفايل)',
                      border: OutlineInputBorder()),
                  hint: const Text('اختر فئة', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  items: profileItems,
                  onChanged: (v) => setState(() => _selectedProfile = v),
                  validator: (v) => (v == null) ? 'الرجاء اختيار فئة' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _charType,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                      labelText: 'نوع أحرف المستخدم',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'mixed', child: Text('حروف وأرقام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'letters', child: Text('حروف فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'numbers', child: Text('أرقام فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  ],
                  onChanged: (v) => setState(() => _charType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _cardType,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                      labelText: 'نوع الكرت', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'username_only', child: Text('اسم مستخدم فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) ,
                    DropdownMenuItem(
                        value: 'username_and_password_equal',
                        child: Text('اسم مستخدم وكلمة مرور متساوية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) ,
                    DropdownMenuItem(
                        value: 'username_and_password_different',
                        child: Text('اسم مستخدم وكلمة مرور مختلفة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) ,
                  ],
                  onChanged: (v) => setState(() => _cardType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTemplate?.profileName,
                  decoration: const InputDecoration(
                      labelText: 'نوع القالب (اختياري)',
                      border: OutlineInputBorder()),
                  hint: const Text('اختر قالب للتصدير إلى PDF'),
                  items: templateItems,
                  onChanged: (v) {
                    setState(() {
                      _selectedTemplate = _templates.firstWhere(
                        (t) => t.profileName == v,
                        orElse: () => _templates.first,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text("ربط كلمة المرور بأول مستخدم"),
                  value: _linkPasswordToFirstUser,
                  onChanged: (newValue) {
                    setState(() {
                      _linkPasswordToFirstUser = newValue ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _sharedUsersController,
                    decoration: const InputDecoration(
                        labelText: 'Shared Users', border: OutlineInputBorder()),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'مطلوب' : null),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                SaveLocationSelector(
                  availableLocations: const [
                    SaveLocation.mikrotikDevice,
                    SaveLocation.localDatabase,
                    SaveLocation.pdfFile,
                    SaveLocation.all,
                  ],
                  defaultLocation: SaveLocation.mikrotikDevice,
                  mode: SelectionMode.single,
                  onChanged: (locations) {
                    _saveLocations = locations;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateUsers,
                  icon: const Icon(Icons.apps_outage_rounded),
                  label: const Text('إنشاء الكروت'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
