// ============================================================
//  UserManagerScreen — شاشة إدارة كروت MikroTik User Manager
//
//  المزايا:
//   - إعدادات قابلة للحفظ (URL + user + pass) في SharedPreferences
//   - اختبار اتصال قبل الدخول
//   - تسجيل دخول آمن
//   - قائمة الكروت مع بحث + pagination
//   - إنشاء كرت فردي (Dialog)
//   - إنشاء جماعي (BottomSheet)
//   - حذف كرت (Long-press)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikrotik_manager/services/user_manager_api.dart';
import 'package:mikrotik_manager/shared/widgets/custom_loading_indicator.dart';
import 'package:mikrotik_manager/snackbar_helpers.dart';

class UserManagerScreen extends StatefulWidget {
  const UserManagerScreen({super.key});

  @override
  State<UserManagerScreen> createState() => _UserManagerScreenState();
}

class _UserManagerScreenState extends State<UserManagerScreen> {
  // إعدادات الاتصال
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  // الحالة
  bool _obscurePass = true;
  bool _isConnecting = false;
  bool _isLoggedIn = false;
  bool _isLoadingUsers = false;

  UserManagerApi? _api;
  List<UmUser> _users = [];
  List<UmUser> _filteredUsers = [];
  List<String> _profiles = [];
  String? _connError;

  // مفاتيح SharedPreferences
  static const _kUrl = 'um_url';
  static const _kUser = 'um_user';
  static const _kPass = 'um_pass';

  @override
  void initState() {
    super.initState();
    _loadSavedCreds();
  }

  Future<void> _loadSavedCreds() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _urlCtrl.text = sp.getString(_kUrl) ?? 'http://ath.vpnbersama.us:13196/userman';
      _userCtrl.text = sp.getString(_kUser) ?? '';
      _passCtrl.text = sp.getString(_kPass) ?? '';
    });
  }

  Future<void> _saveCreds() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUrl, _urlCtrl.text.trim());
    await sp.setString(_kUser, _userCtrl.text.trim());
    await sp.setString(_kPass, _passCtrl.text);
  }

  // ============================================================
  //  Login / Logout
  // ============================================================

  Future<void> _login() async {
    final url = _urlCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (url.isEmpty || user.isEmpty || pass.isEmpty) {
      showErrorSnackBar(context, 'يرجى ملء جميع الحقول');
      return;
    }
    setState(() {
      _isConnecting = true;
      _connError = null;
    });
    try {
      _api = UserManagerApi(baseUrl: url);
      final ok = await _api!.login(username: user, password: pass);
      if (!ok) throw UmException('فشل تسجيل الدخول');
      await _saveCreds();
      setState(() {
        _isLoggedIn = true;
        _isConnecting = false;
      });
      await _refreshAll();
    } on UmException catch (e) {
      setState(() {
        _isConnecting = false;
        _connError = e.message;
      });
      showErrorSnackBar(context, e.message);
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connError = e.toString();
      });
      showErrorSnackBar(context, 'خطأ غير متوقع: $e');
    }
  }

  Future<void> _logout() async {
    _api?.dispose();
    setState(() {
      _isLoggedIn = false;
      _api = null;
      _users = [];
      _filteredUsers = [];
      _profiles = [];
    });
  }

  // ============================================================
  //  جلب البيانات
  // ============================================================

  Future<void> _refreshAll() async {
    await Future.wait([_loadUsers(), _loadProfiles()]);
  }

  Future<void> _loadUsers() async {
    if (_api == null) return;
    setState(() => _isLoadingUsers = true);
    try {
      final list = await _api!.listUsers();
      setState(() {
        _users = list;
        _filteredUsers = list;
        _isLoadingUsers = false;
      });
      _applySearch();
    } on UmException catch (e) {
      setState(() => _isLoadingUsers = false);
      showErrorSnackBar(context, e.message);
    }
  }

  Future<void> _loadProfiles() async {
    if (_api == null) return;
    try {
      final p = await _api!.listProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = p;
      });
    } on UmException {
      // ليست حرجة — نتجاهل الخطأ
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = q.isEmpty
          ? _users
          : _users
              .where((u) =>
                  u.username.toLowerCase().contains(q) ||
                  (u.profile ?? '').toLowerCase().contains(q))
              .toList();
    });
  }

  // ============================================================
  //  إنشاء كرت فردي
  // ============================================================

  Future<void> _showCreateUserDialog() async {
    final uCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    var profile = _profiles.isNotEmpty ? _profiles.first : null;
    var uptimeCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('إنشاء كرت جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: uCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pCtrl,
                  decoration: const InputDecoration(
                    labelText: 'كلمة السر',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: profile,
                  decoration: const InputDecoration(
                    labelText: 'القالب (Profile)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  items: _profiles
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => profile = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: uptimeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'حد الوقت (مثال: 1d 00:00:00)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (uCtrl.text.isEmpty || pCtrl.text.isEmpty) {
                  showErrorSnackBar(context, 'يرجى ملء الاسم وكلمة السر');
                  return;
                }
                try {
                  await _api!.createUser(
                    username: uCtrl.text.trim(),
                    password: pCtrl.text,
                    profile: profile,
                    uptimeLimit: uptimeCtrl.text.trim().isEmpty
                        ? null
                        : uptimeCtrl.text.trim(),
                  );
                  showSuccessSnackBar(context, 'تم إنشاء الكرت بنجاح');
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on UmException catch (e) {
                  showErrorSnackBar(context, e.message);
                }
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );

    if (created == true) await _loadUsers();
  }

  // ============================================================
  //  إنشاء كروت جماعية
  // ============================================================

  Future<void> _showBulkCreateSheet() async {
    final prefixCtrl = TextEditingController(text: 'user');
    final countCtrl = TextEditingController(text: '10');
    final passLenCtrl = TextEditingController(text: '6');
    var profile = _profiles.isNotEmpty ? _profiles.first : null;
    var passwordMode = 'random';
    final samePassCtrl = TextEditingController();
    bool useLetters = true;
    bool useNumbers = true;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'إنشاء كروت جماعية',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: prefixCtrl,
                        decoration: const InputDecoration(
                          labelText: 'البادئة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: countCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'العدد',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: profile,
                  decoration: const InputDecoration(
                    labelText: 'القالب (Profile)',
                    border: OutlineInputBorder(),
                  ),
                  items: _profiles
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => profile = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'random',
                        groupValue: passwordMode,
                        title: const Text('عشوائية'),
                        onChanged: (v) => setState(() => passwordMode = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'same',
                        groupValue: passwordMode,
                        title: const Text('موحّدة'),
                        onChanged: (v) => setState(() => passwordMode = v!),
                      ),
                    ),
                  ],
                ),
                if (passwordMode == 'random') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: passLenCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'طول كلمة السر',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CheckboxListTile(
                          value: useLetters,
                          title: const Text('حروف'),
                          onChanged: (v) => setState(() => useLetters = v ?? true),
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          value: useNumbers,
                          title: const Text('أرقام'),
                          onChanged: (v) => setState(() => useNumbers = v ?? true),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: samePassCtrl,
                    decoration: const InputDecoration(
                      labelText: 'كلمة السر الموحّدة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final count = int.tryParse(countCtrl.text) ?? 0;
                    if (count <= 0 || count > 500) {
                      showErrorSnackBar(context, 'العدد يجب أن يكون بين 1 و 500');
                      return;
                    }
                    if (prefixCtrl.text.isEmpty) {
                      showErrorSnackBar(context, 'البادئة مطلوبة');
                      return;
                    }
                    showDialog(
                      context: ctx,
                      barrierDismissible: false,
                      builder: (_) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomLoadingIndicator(message: 'جاري إنشاء الكروت...'),
                          ],
                        ),
                      ),
                    );
                    try {
                      final created = await _api!.createBulkUsers(
                        count: count,
                        prefix: prefixCtrl.text.trim(),
                        passwordPattern: passwordMode,
                        fixedPassword: passwordMode == 'same'
                            ? samePassCtrl.text
                            : null,
                        profile: profile,
                        passwordLength:
                            int.tryParse(passLenCtrl.text) ?? 6,
                        useLetters: useLetters,
                        useNumbers: useNumbers,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      showSuccessSnackBar(
                          context, 'تم إنشاء ${created.length} كرت بنجاح');
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } on UmException catch (e) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      showErrorSnackBar(context, e.message);
                    }
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('إنشاء الكروت'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true) await _loadUsers();
  }

  // ============================================================
  //  حذف كرت
  // ============================================================

  Future<void> _confirmDelete(UmUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الكرت "${u.username}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api!.deleteUser(u.username);
      showSuccessSnackBar(context, 'تم حذف الكرت');
      await _loadUsers();
    } on UmException catch (e) {
      showErrorSnackBar(context, e.message);
    }
  }

  // ============================================================
  //  UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Manager — كروت عن بُعد'),
        actions: [
          if (_isLoggedIn) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: _refreshAll,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'خروج',
              onPressed: _logout,
            ),
          ],
        ],
      ),
      body: _isLoggedIn ? _buildUsersView() : _buildLoginView(),
      floatingActionButton: _isLoggedIn
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'bulk',
                  onPressed: _showBulkCreateSheet,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('جماعي'),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'single',
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('فردي'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.router, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'اتصال بـ MikroTik User Manager',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل رابط الـ User Manager الكامل (مثال: http://host:13196/userman)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'رابط User Manager',
              hintText: 'http://host:port/userman',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userCtrl,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'اسم المستخدم',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'كلمة السر',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          if (_connError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connError!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isConnecting ? null : _login,
            icon: _isConnecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(_isConnecting ? 'جاري الاتصال...' : 'تسجيل الدخول'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final url = _urlCtrl.text.trim();
              if (url.isEmpty) {
                showErrorSnackBar(context, 'أدخل الرابط أولاً');
                return;
              }
              showSuccessSnackBar(context, 'جاري اختبار الاتصال...');
              final ok = await UserManagerApi.testConnection(url);
              if (ok) {
                showSuccessSnackBar(context, 'الرابط يستجيب');
              } else {
                showErrorSnackBar(context, 'تعذّر الوصول للرابط');
              }
            },
            icon: const Icon(Icons.wifi_find),
            label: const Text('اختبار الرابط'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applySearch(),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو القالب...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _applySearch();
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (_profiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: _profiles
                    .map((p) => Chip(label: Text(p)))
                    .toList(),
              ),
            ),
          ),
        Expanded(
          child: _isLoadingUsers
              ? const CustomLoadingIndicator(message: 'جاري تحميل الكروت...')
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد كروت',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _showCreateUserDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('إنشاء كرت'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (ctx, i) {
                          final u = _filteredUsers[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade100,
                                child: Text(
                                  u.username.isNotEmpty
                                      ? u.username[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color: Colors.deepPurple.shade700),
                                ),
                              ),
                              title: Text(u.username),
                              subtitle: Text(
                                [
                                  if (u.profile != null) 'قالب: ${u.profile}',
                                  if (u.uptimeLimit != null)
                                    'حد الوقت: ${u.uptimeLimit}',
                                  if (u.password != null)
                                    'كلمة السر: ${u.password}',
                                ].join(' • '),
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'delete') _confirmDelete(u);
                                  if (v == 'copy_pass' && u.password != null) {
                                    Clipboard.setData(
                                        ClipboardData(text: u.password!));
                                    showSuccessSnackBar(
                                        context, 'تم نسخ كلمة السر');
                                  }
                                  if (v == 'copy_user') {
                                    Clipboard.setData(
                                        ClipboardData(text: u.username));
                                    showSuccessSnackBar(
                                        context, 'تم نسخ الاسم');
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'copy_user',
                                      child: ListTile(
                                        leading: Icon(Icons.person),
                                        title: Text('نسخ الاسم'),
                                        dense: true,
                                      )),
                                  if (u.password != null)
                                    const PopupMenuItem(
                                        value: 'copy_pass',
                                        child: ListTile(
                                          leading: Icon(Icons.lock),
                                          title: Text('نسخ كلمة السر'),
                                          dense: true,
                                        )),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete,
                                            color: Colors.red),
                                        title: Text('حذف',
                                            style: TextStyle(
                                                color: Colors.red)),
                                        dense: true,
                                      )),
                                ],
                              ),
                              onLongPress: () => _confirmDelete(u),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _searchCtrl.dispose();
    _api?.dispose();
    super.dispose();
  }
}
