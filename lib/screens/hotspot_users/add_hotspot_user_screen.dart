import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/validity_parser.dart';
import '../../utils/show_feedback.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../l10n/translations.dart';

class AddHotspotUserScreen extends ConsumerStatefulWidget {
  const AddHotspotUserScreen({super.key});

  @override
  ConsumerState<AddHotspotUserScreen> createState() =>
      _AddHotspotUserScreenState();
}

class _AddHotspotUserScreenState extends ConsumerState<AddHotspotUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _commentController = TextEditingController();

  String? _selectedProfileId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Provider will auto-load on first access
    // No manual refresh needed
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usersNotifier = ref.read(hotspotUsersProvider.notifier);

      // Get profiles from the provider's value
      final profilesAsync = ref.read(userProfileProvider);
      final profiles = profilesAsync.maybeWhen(
        data: (profiles) => profiles,
        orElse: () => <UserProfile>[],
      );

      if (profiles.isEmpty) {
        FeedbackUtils.showError(
          context,
          AppStrings.of(context).noProfilesAvailableCreateProfileFirst,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the profile name from the selected profile
      final selectedProfile = _selectedProfileId != null
          ? profiles.firstWhere((p) => p.id == _selectedProfileId)
          : profiles.first;

      // Real RouterOS API call
      final service = ref.read(routerOSServiceProvider);
      final client = service.client;
      if (client == null) {
        FeedbackUtils.showError(
          context,
          AppStrings.of(context).notConnectedLoginFirst,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user on RouterOS
      // Get validity and session-timeout from selected profile
      final validity = ValidityParser.formatValidityForMikroTik(
        selectedProfile.validity ?? 'unlimited',
      );

      // Use profile's session-timeout as limit-uptime
      // This is the "Limit Uptime" setting in MikroTik
      final limitUptime = selectedProfile.sessionTimeout;

      // Build Mikhmon-compatible comment for revenue tracking
      final generatedComment = ValidityParser.buildCommentWithExpiry(
        mode: 'up', // Manual users are usually 'up' mode
        validity: selectedProfile.validity ?? 'unlimited',
        price: selectedProfile.price,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      await client.addHotspotUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        profile: selectedProfile.name,
        comment: generatedComment,
        validity: validity == 'unlimited' ? null : validity,
      );

      // Also add to local state for immediate UI update
      await usersNotifier.addUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        profile: selectedProfile.name,
        comment: generatedComment,
        sessionTimeout: limitUptime,
      );

      if (mounted) {
        FeedbackUtils.showSuccess(
          context,
          'User "${_usernameController.text}" created successfully on RouterOS',
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      FeedbackUtils.showError(
        context,
        AppStrings.of(context)
            .failedToCreateUser
            .replaceAll('%s', e.toString()),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          foregroundColor: context.appOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Add Hotspot User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildUsernameField(),
                  SizedBox(height: 16),
                  _buildPasswordField(),
                  SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                  SizedBox(height: 16),
                  _buildProfileSelector(),
                  SizedBox(height: 16),
                  _buildCommentField(),
                  SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: context.appPrimary.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.appPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: context.appPrimary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Create a new hotspot user. The user will be able to login using these credentials.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appOnSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Enter username',
            prefixIcon: Icon(Icons.person_rounded),
            suffixIcon: _usernameController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () {
                      _usernameController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          validator: Validators.validateUsername,
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Enter password',
            prefixIcon: Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: Validators.validatePassword,
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Confirm password',
            prefixIcon: Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfileSelector() {
    final profilesAsync = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'User Profile',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Spacer(),
            // Refresh button
            IconButton(
              icon: Icon(Icons.refresh, size: 18),
              onPressed: () async {
                await ref.read(userProfileProvider.notifier).refresh();
              },
              tooltip: 'Refresh profiles',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
        SizedBox(height: 8),
        profilesAsync.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return Card(
                color: context.appSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: context.appPrimary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No profiles available. Please create a profile first.',
                          style: TextStyle(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/main/profiles'),
                        child: Text(AppStrings.of(context).addProfile),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Find the currently selected profile in the list
            // Safe selection - if _selectedProfileId is null or not found, use first profile
            final selectedProfile = _selectedProfileId != null
                ? profiles.firstWhere(
                    (p) => p.id == _selectedProfileId,
                    orElse: () => profiles.first,
                  )
                : profiles.first;

            // Use the selected profile's ID, which is guaranteed to be in the list
            final validInitialValue = selectedProfile.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: validInitialValue,
                  decoration: InputDecoration(
                    hintText: 'Select profile',
                    prefixIcon: Icon(Icons.card_membership_rounded),
                  ),
                  items: profiles.map((profile) {
                    return DropdownMenuItem<String>(
                      value: profile.id,
                      child: Text(
                        profile.name.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedProfileId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a profile';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.appPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: context.appPrimary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedProfile.priceDisplay} • ${selectedProfile.validityDisplay} • ${selectedProfile.rateLimitDisplay}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appOnSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, __) => Card(
            color: context.appSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: context.appError),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Failed to load profiles',
                              style: TextStyle(color: context.appError),
                            ),
                            SizedBox(height: 4),
                            Text(
                              error.toString(),
                              style: TextStyle(
                                color:
                                    context.appOnSurface.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () async {
                          await ref
                              .read(userProfileProvider.notifier)
                              .refresh();
                        },
                        tooltip: 'Retry',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment (Optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add a note or description',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.comment_rounded),
            ),
          ),
          onFieldSubmitted: (_) => _createUser(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.appPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: context.appOnSurface.withValues(alpha: 0.1),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Create User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
