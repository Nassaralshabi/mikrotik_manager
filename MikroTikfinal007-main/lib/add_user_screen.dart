import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:router_os_client/router_os_client.dart';

import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';
import 'notification_service.dart';

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

  /// الإصلاح: استخدام Random.secure() بدلاً من Random()
  String _generateRandomString(int length, String type) {
    const charsMixed = 'abcdefghijklmnopqrstuvwxyz0123456789';
    const charsLetters = 'abcdefghijklmnopqrstuvwxyz';
    const charsNumbers = '0123456789';
    String chars;
    switch (type) {
      case 'letters': chars = charsLetters; break;
      case 'numbers': chars = charsNumbers; break;
      default: chars = charsMixed;
    }
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

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

      // الإصلاح: استخدام NotificationService المركزي
      NotificationService.instance.notifySingleCardAdded(
        username: username,
        profile: _selectedProfile,
        address: client.address,
      );

      final String cardDetails = _cardType == 'username_only'
          ? 'اسم المستخدم: $username'
          : 'اسم المستخدم: $username\nكلمة المرور: $password';

      if (mounted) {
        showSuccessSnackBar(context, 'تمت إضافة المستخدم "$username" بنجاح');
        Clipboard.setData(ClipboardData(text: cardDetails));
        showSuccessSnackBar(context, 'تم نسخ تفاصيل الكرت!');
        Navigator.of(context).pop(true);
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) showErrorSnackBar(context, 'خطأ في بيانات الدخول: ${e.message}');
    } on MikrotikConnectionException catch (e) {
      if (mounted) showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'فشلت الإضافة. تحقق من الاتصال بالشبكة.');
    } finally {
      client?.close();
      if (mounted) setState(() { _isLoading = false; });
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
      appBar: AppBar(title: const Text('إضافة كرت جديد'), backgroundColor: Theme.of(context).cardColor),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()),
              style: const TextStyle(color: Colors.white),
              validator: (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sharedUsersController,
              decoration: const InputDecoration(labelText: 'Shared Users', border: OutlineInputBorder()),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
                if (int.tryParse(value) == null) return 'الرجاء إدخال رقم صحيح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProfile,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              dropdownColor: Colors.white,
              decoration: const InputDecoration(labelText: 'الفئة (البروفايل)', border: OutlineInputBorder()),
              hint: const Text('اختر فئة', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              items: widget.profiles.map((profile) {
                final profileName = profile['name'] as String;
                return DropdownMenuItem(value: profileName, child: Text(profileName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)));
              }).toList(),
              onChanged: (value) => setState(() { _selectedProfile = value; }),
              validator: (value) => (value == null) ? 'الرجاء اختيار فئة' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _cardType,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              dropdownColor: Colors.white,
              decoration: const InputDecoration(labelText: 'نوع الكرت', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'username_only', child: Text('اسم مستخدم فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'username_and_password_equal', child: Text('اسم مستخدم وكلمة مرور متساوية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'username_and_password_different', child: Text('اسم مستخدم وكلمة مرور مختلفة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              ],
              onChanged: (v) => setState(() => _cardType = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _charType,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              dropdownColor: Colors.white,
              decoration: const InputDecoration(labelText: 'نوع أحرف المستخدم', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'mixed', child: Text('حروف وأرقام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'letters', child: Text('حروف فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'numbers', child: Text('أرقام فقط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              ],
              onChanged: (v) => setState(() => _charType = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _addUser,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('حفظ وإضافة'),
            ),
          ]),
        ),
      ),
    );
  }
}
