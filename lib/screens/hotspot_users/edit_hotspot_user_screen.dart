import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../l10n/translations.dart';

class EditHotspotUserScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const EditHotspotUserScreen({super.key, required this.user});

  @override
  ConsumerState<EditHotspotUserScreen> createState() =>
      _EditHotspotUserScreenState();
}

class _EditHotspotUserScreenState extends ConsumerState<EditHotspotUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _commentController = TextEditingController();

  String? _selectedProfileId;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Trigger profile load if not already loaded
    Future.microtask(() {
      final profilesAsync = ref.read(userProfileProvider);
      if (!profilesAsync.hasValue || profilesAsync.isLoading) {
        ref.read(userProfileProvider.notifier).refresh();
      }
    });
    // Profile will be set after profiles are loaded
    _commentController.text = widget.user['comment'] ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppStrings.of(context).noProfilesAvailableCreateProfileFirst),
              backgroundColor: context.appError,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Get the profile name from the selected profile
      final selectedProfile = _selectedProfileId != null
          ? profiles.firstWhere(
              (p) => p.id == _selectedProfileId,
              orElse: () => UserProfile(id: 'default', name: 'default'),
            )
          : profiles.first;

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
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Get the user's ID
      final userId = widget.user['.id'];
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Update user on RouterOS
      await client.updateHotspotUser(
        id: widget.user['.id'],
        username: widget.user['name'],
        profile: selectedProfile.name,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      // Also update local state for immediate UI update
      await usersNotifier.updateUser(
        id: widget.user['.id'],
        username: widget.user['name'],
        profile: selectedProfile.name,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User "${widget.user['name']}" updated successfully on RouterOS'),
            backgroundColor: context.appSuccess,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context)
                  .failedToUpdateUser
                  .replaceAll('%s', e.toString())),
              backgroundColor: context.appError,
            ),
          );
        }
      }
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
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit User',
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
                  _buildUsernameDisplay(),
                  SizedBox(height: 16),
                  _buildPasswordField(),
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
              Icons.edit_rounded,
              color: context.appPrimary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit user "${widget.user['name']}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.appPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameDisplay() {
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
        Card(
          color: context.appSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: context.appPrimary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.user['name'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password (Optional)',
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
            hintText: 'Enter new password (leave empty to keep current)',
            prefixIcon: Icon(Icons.lock_rounded, size: 20),
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
          validator: Validators.validateOptionalPassword,
        ),
      ],
    );
  }

  Widget _buildProfileSelector() {
    final profilesAsync = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Profile',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
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
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppStrings.of(context).addProfile),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Find the current profile ID based on the user's profile name
            final currentProfileName = widget.user['profile'] ?? 'default';
            final currentProfileId = profiles
                .where((p) => p.name == currentProfileName)
                .firstOrNull
                ?.id;

            // Find the selected profile in the list, defaulting to first profile
            final selectedProfile = profiles.firstWhere(
              (p) => p.id == (_selectedProfileId ?? currentProfileId),
              orElse: () => profiles.first,
            );

            // Use the selected profile's ID, which is guaranteed to be in the list
            final validInitialValue = selectedProfile.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: validInitialValue,
                  decoration: InputDecoration(
                    hintText: 'Select profile',
                    prefixIcon: Icon(Icons.card_membership_rounded, size: 20),
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
          error: (_, __) => Card(
            color: context.appSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.appError),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Failed to load profiles',
                      style: TextStyle(color: context.appError),
                    ),
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
          onFieldSubmitted: (_) => _updateUser(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateUser,
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
                  Icon(Icons.save_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Update User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
