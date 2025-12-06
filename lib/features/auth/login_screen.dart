import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/data_mode.dart';
import 'session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController(text: '');
  final _ipController = TextEditingController(text: '192.168.88.1');
  final _portController = TextEditingController(text: '8728');
  final _userController = TextEditingController(text: 'admin');
  final _passController = TextEditingController();
  DataMode _dataMode = DataMode.router;
  bool _forceV6Api = true;
  bool _useSSL = false;

  bool get _needsRouterCredentials => _dataMode != DataMode.mock;
  bool get _needsBackendUrl => _dataMode == DataMode.backend;

  @override
  void dispose() {
    _serverController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final session = context.read<SessionController>();
    final port = int.tryParse(_portController.text.trim()) ?? 8728;
    await session.login(
      dataMode: _dataMode,
      backendUrl: _serverController.text.trim(),
      username: _userController.text.trim(),
      password: _passController.text.trim(),
      ip: _ipController.text.trim(),
      port: port,
      useSSL: _useSSL,
      forceV6Api: _forceV6Api,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isLoading = session.status == SessionStatus.loading;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'NUM Router Manager',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<DataMode>(
                          value: _dataMode,
                          decoration: const InputDecoration(labelText: 'مصدر البيانات'),
                          items: const [
                            DropdownMenuItem(
                              value: DataMode.router,
                              child: Text('اتصال مباشر بالراوتر (RouterOS API)'),
                            ),
                            DropdownMenuItem(
                              value: DataMode.backend,
                              child: Text('خادم PHP - السكربت القديم'),
                            ),
                            DropdownMenuItem(
                              value: DataMode.mock,
                              child: Text('وضع المحاكاة (بيانات افتراضية)'),
                            ),
                          ],
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => _dataMode = value);
                                },
                        ),
                        const SizedBox(height: 16),
                        
                        // خيارات RouterOS v6
                        if (_dataMode == DataMode.router) ..[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info, color: Colors.blue, size: 20),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'RouterOS v6 مدعوم بالكامل',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  title: const Text('فرض استخدام RouterOS v6 API'),
                                  subtitle: const Text('موصى به لـ RouterOS v6.x'),
                                  value: _forceV6Api,
                                  onChanged: isLoading
                                      ? null
                                      : (value) => setState(() => _forceV6Api = value ?? false),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                CheckboxListTile(
                                  title: const Text('استخدام SSL'),
                                  subtitle: const Text('المنفذ 8729 - أكثر أماناً'),
                                  value: _useSSL,
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _useSSL = value ?? false;
                                            if (_useSSL) {
                                              _portController.text = '8729';
                                            } else {
                                              _portController.text = '8728';
                                            }
                                          });
                                        },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_needsBackendUrl) ...[
                          TextFormField(
                            controller: _serverController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'رابط خادم NUM (HTTP)',
                              hintText: 'https://example.com/reference_backend',
                            ),
                            validator: (value) {
                              if (!_needsBackendUrl) return null;
                              return value == null || value.isEmpty ? 'أدخل رابط الخادم' : null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _ipController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'عنوان الراوتر (RouterOS)'),
                          validator: (value) {
                            if (!_needsRouterCredentials) return null;
                            return value == null || value.isEmpty ? 'أدخل العنوان' : null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'المنفذ'),
                          validator: (value) {
                            if (!_needsRouterCredentials) return null;
                            return value == null || value.isEmpty ? 'أدخل المنفذ' : null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _userController,
                          decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                          validator: (value) {
                            if (!_needsRouterCredentials) return null;
                            return value == null || value.isEmpty ? 'أدخل الاسم' : null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'كلمة المرور'),
                          validator: (value) {
                            if (!_needsRouterCredentials) return null;
                            return value == null || value.isEmpty ? 'أدخل كلمة المرور' : null;
                          },
                        ),
                        if (_dataMode == DataMode.mock) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'سيتم استخدام بيانات تجريبية لعرض الواجهات دون الحاجة لأي اتصال.',
                            textAlign: TextAlign.center,
                          ),
                        ] else
                          const SizedBox(height: 8),
                        if (session.status == SessionStatus.error && session.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            session.error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('تسجيل الدخول'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
