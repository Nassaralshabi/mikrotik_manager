import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../utils/validity_parser.dart';
import '../../services/models.dart';
import '../../services/models/voucher.dart';
import '../../services/log_service.dart';
import '../../services/cache_service.dart';
import '../../l10n/translations.dart';
import 'voucher_preview_screen.dart';

// Enum for user mode
enum UserMode { up, vc }

// Enum for character type
enum CharType {
  lower,
  upper,
  upplow,
  mix,
  mix1,
  mix2,
  num,
  lower1,
  upper1,
  upplow1,
}

// Extension to display names
extension CharTypeExtension on CharType {
  String get displayName {
    switch (this) {
      case CharType.lower:
        return 'abcd';
      case CharType.upper:
        return 'ABCD';
      case CharType.upplow:
        return 'aBcD';
      case CharType.mix:
        return '5ab2c34d';
      case CharType.mix1:
        return '5AB2C34D';
      case CharType.mix2:
        return '5aB2c34D';
      case CharType.num:
        return '1234';
      case CharType.lower1:
        return 'abcd2345';
      case CharType.upper1:
        return 'ABCD2345';
      case CharType.upplow1:
        return 'aBcD2345';
    }
  }
}

class VoucherGenerationScreen extends ConsumerStatefulWidget {
  const VoucherGenerationScreen({super.key});

  @override
  ConsumerState<VoucherGenerationScreen> createState() =>
      _VoucherGenerationScreenState();
}

class _VoucherGenerationScreenState
    extends ConsumerState<VoucherGenerationScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _qtyController = TextEditingController(text: '1');
  final _prefixController = TextEditingController();
  final _dataLimitController = TextEditingController();
  final _commentController = TextEditingController();

  // Form values
  String _selectedServer = 'all';
  UserMode _userMode = UserMode.up;
  int _nameLength = 4;
  CharType _charType = CharType.lower;
  String? _selectedProfile;

  // Loading state
  bool _isGenerating = false;
  bool _generationSuccessful = false;
  String? _generationStatus;

  // Store generated vouchers
  final List<Voucher> _generatedVouchers = [];

  @override
  void initState() {
    super.initState();
    // Trigger profile load if not already loaded
    Future.microtask(() {
      final profilesNotifier = ref.read(userProfileProvider.notifier);
      // Force refresh to ensure we get latest data from API
      profilesNotifier.refresh();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _prefixController.dispose();
    _dataLimitController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Get available character types based on user mode
  List<CharType> get _availableCharTypes {
    if (_userMode == UserMode.up) {
      return [
        CharType.lower,
        CharType.upper,
        CharType.upplow,
        CharType.mix,
        CharType.mix1,
        CharType.mix2,
      ];
    } else {
      // Voucher mode (vc)
      return [
        CharType.lower1,
        CharType.upper1,
        CharType.upplow1,
        CharType.num,
        CharType.mix,
        CharType.mix1,
        CharType.mix2,
      ];
    }
  }

  // Reset form to defaults
  void _resetForm() {
    setState(() {
      _qtyController.text = '1';
      _prefixController.clear();
      _dataLimitController.clear();
      _commentController.clear();
      _selectedServer = 'all';
      _userMode = UserMode.up;
      _nameLength = 4;
      _charType = CharType.lower;
      _selectedProfile = null;
      _isGenerating = false;
      _generationSuccessful = false;
      _generationStatus = null;
    });
  }

  // Generate vouchers
  Future<void> _generateVouchers() async {
    // Guard against duplicate calls
    if (_isGenerating) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProfile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).pleaseSelectProfile)),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 1;

    // Get selected profile's session-timeout
    final profilesAsync = ref.read(userProfileProvider);
    final profiles = profilesAsync.valueOrNull ?? [];
    final selectedProfileObj = profiles.firstWhere(
      (p) => p.name == _selectedProfile,
      orElse: () => UserProfile(id: '', name: _selectedProfile!),
    );
    final profileSessionTimeout = selectedProfileObj.sessionTimeout;

    // Real RouterOS API call
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;

    if (client == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).notConnectedLoginFirst),
            backgroundColor: context.appError,
          ),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationStatus = 'Generating vouchers on RouterOS...';
      _generatedVouchers.clear();
    });

    try {
      // Generate vouchers one by one to avoid overwhelming the router
      for (int i = 1; i <= qty; i++) {
        // Update progress
        setState(() {
          _generationStatus = 'Generated $i of $qty vouchers...';
        });

        // Generate random voucher
        final username = _generateUsername(i);
        final password =
            _userMode == UserMode.vc ? username : _generatePassword();
        final comment = _buildComment();

        // Get validity from selected profile's session-timeout
        final validity = profileSessionTimeout ?? '';
        final dataLimit = _parseDataLimit(_dataLimitController.text.trim());

        // Calculate expiration date
        final voucher = Voucher(
          username: username,
          password: password,
          profile: _selectedProfile ?? 'default',
          validity: validity.isEmpty ? null : validity,
          dataLimit: dataLimit,
          comment: comment.isEmpty ? null : comment,
          createdAt: DateTime.now(),
          firstUsedAt: null,
          remainingSeconds: null,
        );

        // Add user via RouterOS API
        await client.addHotspotUser(
          username: username,
          password: password,
          profile: _selectedProfile ?? 'default',
          comment: comment,
          dataLimit: dataLimit,
        );

        // Store generated voucher
        _generatedVouchers.add(voucher);

        // Small delay between requests to avoid overwhelming the router
        if (i < qty) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      setState(() {
        _isGenerating = false;
        _generationSuccessful = true;
        _generationStatus = 'Successfully generated $qty vouchers!';
      });

      // Save vouchers to cache
      final cache = ref.read(cacheServiceProvider);
      await cache
          .addVouchers(_generatedVouchers.map((v) => v.toJson()).toList());

      // Invalidate vouchers provider to refresh the list
      ref.invalidate(vouchersProvider);
      ref.invalidate(hotspotUsersProvider);

      // Log voucher creation
      await LogService.logVoucherCreated(
        _selectedProfile ?? 'default',
        qty,
        'User',
      );

      // Navigate to voucher preview screen
      if (mounted) {
        final cache = CacheService();
        final settings = cache.getAppSettings();
        final companyName = settings?['companyName'] as String?;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoucherPreviewScreen(
              vouchers: _generatedVouchers,
              profileName: _selectedProfile ?? 'default',
              companyName: companyName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context)
                .failedToGenerateVouchers
                .replaceAll('%s', e.toString())),
            backgroundColor: context.appError,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Generate random username based on settings
  String _generateUsername(int index) {
    final prefix = _prefixController.text;
    final seed = DateTime.now().millisecondsSinceEpoch + index;
    final random = Random(seed);
    final chars = _getCharacters();
    final namePart = List.generate(_nameLength, (i) {
      return chars[random.nextInt(chars.length)];
    }).join();

    return '$prefix$namePart';
  }

  // Generate random password (for up mode)
  String _generatePassword() {
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    const nums = '0123456789';
    return List.generate(_nameLength, (i) {
      return nums[random.nextInt(nums.length)];
    }).join();
  }

  // Get character set based on selected type
  String _getCharacters() {
    switch (_charType) {
      case CharType.lower:
        return 'abcdefghijklmnopqrstuvwxyz';
      case CharType.upper:
        return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case CharType.upplow:
        return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case CharType.mix:
      case CharType.lower1:
        return 'abcdefghijklmnopqrstuvwxyz0123456789';
      case CharType.mix1:
      case CharType.upper1:
        return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      case CharType.mix2:
      case CharType.upplow1:
        return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      case CharType.num:
        return '0123456789';
    }
  }

  // Build comment string with expiry date
  String _buildComment() {
    final mode = _userMode == UserMode.up ? 'up' : 'vc';
    final comment = _commentController.text.trim();

    // Use profile's session-timeout and price for comment
    final profilesAsync = ref.read(userProfileProvider);
    final profiles = profilesAsync.valueOrNull ?? [];
    String validity = '';
    double? price;
    
    if (_selectedProfile != null) {
      final selectedProfileObj = profiles.firstWhere(
        (p) => p.name == _selectedProfile,
        orElse: () => UserProfile(id: '', name: _selectedProfile!),
      );
      // Use the parsed validity and price from the profile
      validity = (selectedProfileObj.validity != null && selectedProfileObj.validity!.isNotEmpty && selectedProfileObj.validity != 'unlimited')
          ? selectedProfileObj.validity!
          : (selectedProfileObj.sessionTimeout ?? '');
      price = selectedProfileObj.price;
    }

    return ValidityParser.buildCommentWithExpiry(
      mode: mode,
      validity: validity,
      price: price,
      comment: comment.isEmpty ? null : comment,
    );
  }

  // Parse data limit string (e.g., "5G", "1500M") to bytes for MikroTik
  String? _parseDataLimit(String dataLimit) {
    if (dataLimit.isEmpty) {
      return null;
    }

    // Match pattern: number followed by unit
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-z]+)$', caseSensitive: false)
        .firstMatch(dataLimit);
    if (match == null) {
      return null;
    }

    final value = double.tryParse(match.group(1) ?? '');
    final unit = (match.group(2) ?? '').toLowerCase();

    if (value == null) {
      return null;
    }

    // Convert to bytes
    int bytes;
    switch (unit) {
      case 'k':
      case 'kb':
        bytes = (value * 1024).toInt();
        break;
      case 'm':
      case 'mb':
        bytes = (value * 1024 * 1024).toInt();
        break;
      case 'g':
      case 'gb':
        bytes = (value * 1024 * 1024 * 1024).toInt();
        break;
      case 't':
      case 'tb':
        bytes = (value * 1024 * 1024 * 1024 * 1024).toInt();
        break;
      default:
        return null;
    }

    return bytes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(userProfileProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          title: Text(
            'Generate Vouchers',
            style: TextStyle(color: context.appOnSurface),
          ),
          iconTheme: IconThemeData(color: context.appOnSurface),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetForm,
              tooltip: 'Reset Form',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100 + MediaQuery.of(context).padding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General Settings Card
                _buildSectionCard(
                  title: 'General Settings',
                  icon: Icons.settings,
                  child: Column(
                    children: [
                      // Quantity
                      _buildNumberField(
                        label: 'Quantity',
                        controller: _qtyController,
                        min: 1,
                        max: 500,
                        icon: Icons.format_list_numbered,
                        helperText: 'Number of vouchers to generate (1-500)',
                      ),

                      SizedBox(height: 16),

                      // Server Selection
                      _buildDropdown<String>(
                        label: 'Server',
                        value: _selectedServer,
                        items: [
                          DropdownMenuItem(
                              value: 'all',
                              child: Text(AppStrings.of(context).filterAll)),
                        ],
                        icon: Icons.router,
                        onChanged: (value) =>
                            setState(() => _selectedServer = value ?? 'all'),
                      ),

                      SizedBox(height: 16),

                      // User Mode
                      _buildDropdown<UserMode>(
                        label: 'User Mode',
                        value: _userMode,
                        items: [
                          DropdownMenuItem(
                            value: UserMode.up,
                            child: Text(AppStrings.of(context)
                                .usernamePasswordSeparate),
                          ),
                          DropdownMenuItem(
                            value: UserMode.vc,
                            child: Text(
                                AppStrings.of(context).usernameEqualPassword),
                          ),
                        ],
                        icon: Icons.person,
                        onChanged: (value) {
                          setState(() {
                            _userMode = value ?? UserMode.up;
                            // Reset char type when mode changes
                            _charType = _availableCharTypes.first;
                          });
                        },
                      ),

                      SizedBox(height: 16),

                      // Name Length
                      _buildDropdown<int>(
                        label: 'Name Length',
                        value: _nameLength,
                        items: [4, 5, 6, 7, 8].map((length) {
                          return DropdownMenuItem(
                            value: length,
                            child: Text(AppStrings.of(context)
                                .characters
                                .replaceAll('%d', length.toString())),
                          );
                        }).toList(),
                        icon: Icons.text_fields,
                        onChanged: (value) =>
                            setState(() => _nameLength = value ?? 4),
                      ),

                      SizedBox(height: 16),

                      // Prefix
                      _buildTextField(
                        label: 'Prefix',
                        controller: _prefixController,
                        icon: Icons.label,
                        helperText: 'Optional prefix for usernames',
                      ),

                      SizedBox(height: 16),

                      // Character Type
                      _buildDropdown<CharType>(
                        label: 'Character Type',
                        value: _charType,
                        items: _availableCharTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        icon: Icons.font_download,
                        onChanged: (value) =>
                            setState(() => _charType = value ?? CharType.lower),
                      ),

                      SizedBox(height: 16),

                      // Profile
                      profilesAsync.when(
                        data: (profiles) {
                          // Only set value if it exists in the current profiles list
                          final validValue =
                              profiles.any((p) => p.name == _selectedProfile)
                                  ? _selectedProfile
                                  : null;

                          final items = profiles.isNotEmpty
                              ? profiles.map((profile) {
                                  return DropdownMenuItem(
                                    value: profile.name,
                                    child: Text(profile.name),
                                  );
                                }).toList()
                              : [
                                  DropdownMenuItem(
                                    value: 'default',
                                    child: Text(AppStrings.of(context)
                                        .defaultNoProfilesFound),
                                  ),
                                ];

                          return _buildDropdown<String>(
                            label: 'Profile',
                            value: validValue,
                            items: items,
                            icon: Icons.pie_chart,
                            hint: Text(AppStrings.of(context).selectProfile),
                            onChanged: (value) =>
                                setState(() => _selectedProfile = value),
                            validator: (value) => value == null
                                ? 'Please select a profile'
                                : null,
                          );
                        },
                        loading: () => Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Error loading profiles',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildDropdown<String>(
                              label: 'Profile',
                              value: _selectedProfile,
                              items: [
                                DropdownMenuItem(
                                    value: 'default',
                                    child: Text(AppStrings.of(context)
                                        .defaultNoProfilesFound)),
                              ],
                              icon: Icons.pie_chart,
                              onChanged: (value) =>
                                  setState(() => _selectedProfile = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Limits Card
                _buildSectionCard(
                  title: 'Limits',
                  icon: Icons.speed,
                  child: Column(
                    children: [
                      // Data Limit
                      _buildTextField(
                        label: 'Data Limit',
                        controller: _dataLimitController,
                        icon: Icons.data_usage,
                        helperText: 'e.g., 5G, 1500M (unlimited if empty)',
                        textCapitalization: TextCapitalization.characters,
                      ),

                      SizedBox(height: 16),

                      // Comment
                      _buildTextField(
                        label: 'Comment',
                        controller: _commentController,
                        icon: Icons.comment,
                        helperText: 'Optional comment/suffix',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Status Message
                if (_generationStatus != null)
                  Container(
                    width: double.infinity,
                    padding: _generationSuccessful
                        ? const EdgeInsets.fromLTRB(12, 12, 12, 8)
                        : const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isGenerating
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isGenerating
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _generationSuccessful
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _generationStatus!,
                                      style: TextStyle(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ref.invalidate(hotspotUsersProvider);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.appSuccess,
                                    foregroundColor: context.appOnSurface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(AppStrings.of(context).showUsers),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              if (_isGenerating)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _generationStatus!,
                                  style: TextStyle(
                                    color: _isGenerating
                                        ? Colors.blue.shade200
                                        : Colors.green.shade200,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                SizedBox(height: 24),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateVouchers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isGenerating
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.confirmation_number),
                              SizedBox(width: 8),
                              Text(
                                'Generate Vouchers',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 16),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isGenerating ? null : _resetForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appOnSurface,
                      side: BorderSide(color: Colors.grey.shade600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text(
                          'Reset Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build section card
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appOnSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appOnSurface.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: context.appPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  // Build text field
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? helperText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: TextStyle(color: context.appOnSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
        hintText: helperText,
        hintStyle:
            TextStyle(color: context.appOnSurface.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: context.appPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: context.appOnSurface.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: context.appOnSurface.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.appPrimary),
        ),
        filled: true,
        fillColor: context.appSurface,
      ),
    );
  }

  // Build number field
  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
    required IconData icon,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: context.appOnSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
        hintText: helperText,
        hintStyle:
            TextStyle(color: context.appOnSurface.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: context.appPrimary),
        suffix: Text('($min - $max)',
            style:
                TextStyle(color: context.appOnSurface.withValues(alpha: 0.5))),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: context.appOnSurface.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: context.appOnSurface.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.appPrimary),
        ),
        filled: true,
        fillColor: context.appSurface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a quantity';
        }
        final number = int.tryParse(value);
        if (number == null) {
          return 'Please enter a valid number';
        }
        if (number < min || number > max) {
          return 'Quantity must be between $min and $max';
        }
        return null;
      },
    );
  }

  // Build dropdown
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required IconData icon,
    required void Function(T?) onChanged,
    Widget? hint,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items.map((item) {
        String text;
        if (item.child is Text) {
          text = (item.child as Text).data ?? '';
        } else {
          text = item.value?.toString() ?? '';
        }
        return DropdownMenuItem<T>(
          value: item.value,
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      hint: hint,
      validator: validator,
      iconEnabledColor: context.appPrimary,
      dropdownColor: context.appSurface,
      style: TextStyle(color: context.appOnSurface),
      isExpanded: true,
      menuMaxHeight: 200,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: context.appPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: context.appOnSurface.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: context.appOnSurface.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.appPrimary),
        ),
        filled: true,
        fillColor: context.appSurface,
      ),
    );
  }
}
