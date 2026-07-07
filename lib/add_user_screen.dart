// ملف: add_user_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:router_os_client/router_os_client.dart';
import 'dart:math';
import 'package:dio/dio.dart';

import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';
import 'shared/widgets/save_location_selector.dart';
import 'core/services/card_save_service.dart';

class AddUserScreen extends StatefulWidget {
  final List<Map<String, dynamic>> profiles;
  final bool isVersion7OrNewer;
  final String customer;

  const AddUserScreen({
    super.key,
    required this.profiles,
    required this.isVersion7OrNewer,
    required this.customer,
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _usernameController = TextEditingController();
  final _sharedUsersController = TextEditingController(text: '1');
  String? _selectedProfile;
  String _cardType = 'username_only';
  String _charType = 'numbers';
  List<SaveLocation> _saveLocations = [SaveLocation.mikrotikDevice];

  final String telegramBotToken = '';
  final String telegramChatId = '';

  Future<void> _sendTelegramMessage(String message) async {
    final dio = Dio();
    final url = 'https://api.telegram.org/bot$telegramBotToken/sendMessage';
    try {
      await dio.post(url, data: {
        'chat_id': telegramChatId,
        'text': message,
      });
    } catch (e) {
      // print("Failed to send Telegram message: $e");
    }
  }

  String _generateRandomString(int length, String type) {
    const charsMixed = 'abcdefghijklmnopqrstuvwxyz0123456789';
    const charsLetters = 'abcdefghijklmnopqrstuvwxyz';
    const charsNumbers = '0123456789';
    String chars;
    switch (type) {
      case 'letters':
        chars = charsLetters;
        break;
      case 'numbers':
        chars = charsNumbers;
        break;
      default:
        chars = charsMixed;
    }
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final username = _usernameController.text.trim();
      final sharedUsers = _sharedUsersController.text.trim();
      
      String password = "";
      if (_cardType == 'username_and_password_equal') {
        password = username;
      } else if (_cardType == 'username_and_password_different') {
        password = _generateRandomString(8, _charType);
      }

      final List<String> addUserCommand = [
        '/tool/user-manager/user/add',
        '=username=$username',
        '=password=$password',
        '=shared-users=$sharedUsers',
      ];
      if (!widget.isVersion7OrNewer) {
        addUserCommand.add('=customer=${widget.customer}');
      }
      await client.talk(addUserCommand);

      await client.talk([
        '/tool/user-manager/user/create-and-activate-profile',
        '=customer=${widget.customer}',
        '=numbers=$username',
        '=profile=$_selectedProfile',
      ]);

      final String notificationMessage = "تم إضافة كرت فردي جديد بنجاح!\n" 
          "IP: ${client.address}\n" 
          "اسم المستخدم: $username\n" 
          "الفئة: $_selectedProfile";
      _sendTelegramMessage(notificationMessage);

      final String cardDetails = _cardType == 'username_only'
          ? 'اسم المستخدم: $username'
          : 'اسم المستخدم: $username\nكلمة المرور: $password';

      if (mounted) {
        showSuccessSnackBar(context, 'تمت إضافة المستخدم "$username" بنجاح');

        // حفظ في الوجهات الإضافية حسب اختيار المستخدم
        for (final location in _saveLocations) {
          if (location != SaveLocation.mikrotikDevice) {
            final result = await CardSaveService.instance.saveCard(
              card: CardSaveData(
                username: username,
                password: password.isNotEmpty ? password : null,
                profileName: _selectedProfile,
                sharedUsers: int.tryParse(sharedUsers) ?? 1,
              ),
              location: location,
              context: context,
            );
            debugPrint('[SaveLocation] ${location.name}: ${result.summary}');
          }
        }

        // نسخ إلى الحافظة (دائماً)
        Clipboard.setData(ClipboardData(text: cardDetails));
        if (_saveLocations.contains(SaveLocation.pdfFile) || _saveLocations.contains(SaveLocation.all)) {
          showSuccessSnackBar(context, 'تم حفظ الكرت في الملفات والـ PDF');
        }
        Navigator.of(context).pop(true);
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'خطأ في بيانات الدخول: ${e.message}');
      }
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'فشلت الإضافة. تحقق من الاتصال بالشبكة.');
      }
    } finally {
      // لا نغلق الاتصال - تجمع الاتصالات يديره تلقائياً
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _sharedUsersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة كرت جديد'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: 'اسم المستخدم', border: OutlineInputBorder()),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sharedUsersController,
                decoration: const InputDecoration(
                    labelText: 'Shared Users', border: OutlineInputBorder()),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  if (int.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح';
                  }
                  return null;
                },
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
                items: [
                  for (final profile in widget.profiles)
                    DropdownMenuItem(
                      value: profile['name'] as String,
                      child: Text(profile['name'] as String, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProfile = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'الرجاء اختيار فئة';
                  }
                  return null;
                },
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
                      value: 'username_only', child: Text('اسم مستخدم فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(
                      value: 'username_and_password_equal',
                      child: Text('اسم مستخدم وكلمة مرور متساوية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(
                      value: 'username_and_password_different',
                      child: Text('اسم مستخدم وكلمة مرور مختلفة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                ],
                onChanged: (v) => setState(() => _cardType = v!),
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
                  DropdownMenuItem(
                      value: 'mixed', child: Text('حروف وأرقام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(
                      value: 'letters', child: Text('حروف فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(
                      value: 'numbers', child: Text('أرقام فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                ],
                onChanged: (v) => setState(() => _charType = v!),
              ),
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
              ElevatedButton(
                onPressed: _isLoading ? null : _addUser,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Text('حفظ وإضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
