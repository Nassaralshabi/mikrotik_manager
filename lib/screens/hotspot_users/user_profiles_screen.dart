import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../services/cache_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/skeleton_loader.dart';
import '../../l10n/translations.dart';
import 'add_edit_profile_screen.dart';

class UserProfilesScreen extends ConsumerStatefulWidget {
  const UserProfilesScreen({super.key});

  @override
  ConsumerState<UserProfilesScreen> createState() => _UserProfilesScreenState();
}

class _UserProfilesScreenState extends ConsumerState<UserProfilesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final profilesAsync = ref.watch(userProfileProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(userProfileProvider.notifier).refresh();
          },
          child: profilesAsync.when(
            data: (profiles) {
              if (profiles.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: profiles.length,
                physics: const AlwaysScrollableScrollPhysics(),
                itemExtent: 190,
                addRepaintBoundaries: true,
                addAutomaticKeepAlives: true,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    key: ValueKey(profiles[index].id),
                    child: _ProfileCard(
                      profile: profiles[index],
                      onTap: () => _showProfileDetails(profiles[index]),
                      onMoreTap: () => _showProfileOptions(profiles[index]),
                    ),
                  );
                },
              );
            },
            loading: () => SizedBox(
              height: 400,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => SkeletonLoaders.userListItem(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddProfile,
          backgroundColor: context.appPrimary,
          foregroundColor: Colors.white,
          child: Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.appSurface,
      foregroundColor: context.appOnSurface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go('/main'),
        tooltip: 'Back',
      ),
      title: Text(
        'User Profiles',
        style: TextStyle(
          color: context.appOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded),
          onPressed: () {
            ref.read(userProfileProvider.notifier).refresh();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_rounded,
            size: 80,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 24),
          Text(
            'No Profiles Found',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first user profile to get started',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: context.appError,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load profiles',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showProfileDetails(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _ProfileDetailsSheet(
        profile: profile,
        onEdit: () => _navigateToEditProfile(profile),
        onDelete: () => _confirmDeleteProfile(profile),
      ),
    );
  }

  void _showProfileOptions(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility_rounded),
              title: Text(AppStrings.of(context).viewDetails),
              onTap: () {
                Navigator.pop(context);
                _showProfileDetails(profile);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_rounded),
              title: Text(AppStrings.of(context).editProfile),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditProfile(profile);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: context.appError),
              title: Text(
                'Delete Profile',
                style: TextStyle(color: context.appError),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProfile(profile);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProfileScreen(),
      ),
    );
  }

  void _navigateToEditProfile(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProfileScreen(profile: profile),
      ),
    );
  }

  void _confirmDeleteProfile(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Delete Profile',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'Are you sure you want to delete "${profile.name}" profile? This action cannot be undone.',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final primaryColor = context.appPrimary;
              await ref
                  .read(userProfileProvider.notifier)
                  .deleteProfile(profile.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.of(context)
                        .profileDeleted
                        .replaceAll('%s', profile.name)),
                    backgroundColor: primaryColor,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: context.appError,
            ),
            child: Text(AppStrings.of(context).deleteProfile),
          ),
        ],
      ),
    );
  }
}

// Extracted as separate widget for better performance with RepaintBoundary
String _formatPrice(double? price, {String? profileName}) {
  if (price == null || price == 0) {
    if (profileName != null) {
      final cache = CacheService();
      final localPrices = cache.getProfilePrices();
      final localPrice = localPrices[profileName];
      if (localPrice != null && localPrice > 0) {
        final settings = cache.getAppSettings();
        final currencyCode = settings?['currency'] as String? ?? 'USD';
        final currencyInfo = CurrencyData.fromCode(currencyCode);
        return CurrencyFormatter.format(localPrice, currencyInfo);
      }
    }
    return 'Free';
  }
  final cache = CacheService();
  final settings = cache.getAppSettings();
  final currencyCode = settings?['currency'] as String? ?? 'USD';
  final currencyInfo = CurrencyData.fromCode(currencyCode);
  return CurrencyFormatter.format(price, currencyInfo);
}

class _ProfileCard extends ConsumerWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconContainer(context),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildProfileInfo(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded),
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    onPressed: onMoreTap,
                  ),
                ],
              ),
              SizedBox(height: 16),
              _ProfileInfoGrid(profile: profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appPrimary,
            context.appPrimary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.card_membership_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name.toUpperCase(),
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _formatPrice(profile.price),
          style: TextStyle(
            color: context.appPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Extracted as separate widget for better performance
class _ProfileInfoGrid extends StatelessWidget {
  final UserProfile profile;

  const _ProfileInfoGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.speed_rounded,
          label: 'Rate Limit',
          value: profile.rateLimitDisplay,
        ),
        SizedBox(height: 5),
        _InfoRow(
          icon: Icons.access_time_rounded,
          label: 'Validity',
          value: profile.validityDisplay,
        ),
        SizedBox(height: 5),
        _InfoRow(
          icon: Icons.people_rounded,
          label: 'Shared Users',
          value: profile.sharedUsersDisplay,
        ),
      ],
    );
  }
}

// Optimized info row widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: context.appOnSurface.withValues(alpha: 0.5),
        ),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.6),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}

// Extracted as separate widget for better performance
class _ProfileDetailsSheet extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileDetailsSheet({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragHandle(context),
            _buildHeader(context),
            SizedBox(height: 24),
            _ProfileDetailItem(
              icon: Icons.speed_rounded,
              label: 'Rate Limit',
              value: profile.rateLimitDisplay,
            ),
            SizedBox(height: 16),
            _ProfileDetailItem(
              icon: Icons.access_time_rounded,
              label: 'Validity',
              value: profile.validityDisplay,
            ),
            SizedBox(height: 16),
            _ProfileDetailItem(
              icon: Icons.people_rounded,
              label: 'Shared Users',
              value: profile.sharedUsersDisplay,
            ),
            SizedBox(height: 16),
            _ProfileDetailItem(
              icon: Icons.logout_rounded,
              label: 'Auto Logout',
              value: profile.autologout == true ? 'Enabled' : 'Disabled',
            ),
            SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.appOnSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.appPrimary,
                context.appPrimary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.card_membership_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name.toUpperCase(),
                style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
          _formatPrice(profile.price, profileName: profile.name),
                style: TextStyle(
                  color: context.appPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            icon: Icon(Icons.edit_rounded),
            label: Text(AppStrings.of(context).editProfile),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appPrimary,
              side: BorderSide(color: context.appPrimary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            icon: Icon(Icons.delete_rounded),
            label: Text(AppStrings.of(context).deleteProfile),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appError,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// Extracted detail item widget for better performance
class _ProfileDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: context.appPrimary,
          ),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
