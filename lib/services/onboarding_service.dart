import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';

class OnboardingService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const _completedKey = 'onboarding_completed';
  static const _agreedKey = 'user_agreement_accepted';
  static const _lastVersionKey = 'last_seen_version';
  static const _setupCompletedKey = 'setup_completed';

  // Current app version - update this when releasing new features
  static const currentVersion = '1.0.0';

  // What's new content per version
  static const _changelogs = {
    '1.0.0': [
      'Hotspot user management',
      'Bulk voucher generation',
      'Real-time system monitoring',
      'Multi-router support',
      'Revenue tracking',
      'Activity logs',
    ],
  };

  static Future<bool> isCompleted() async {
    final value = await _storage.read(key: _completedKey);
    return value == 'true';
  }

  static Future<void> setCompleted() async {
    await _storage.write(key: _completedKey, value: 'true');
  }

  static Future<bool> isAgreementAccepted() async {
    final value = await _storage.read(key: _agreedKey);
    return value == 'true';
  }

  static Future<void> setAgreementAccepted() async {
    await _storage.write(key: _agreedKey, value: 'true');
  }

  static Future<String?> getLastSeenVersion() async {
    return await _storage.read(key: _lastVersionKey);
  }

  static Future<void> setLastSeenVersion(String version) async {
    await _storage.write(key: _lastVersionKey, value: version);
  }

  static Future<bool> isSetupCompleted() async {
    final value = await _storage.read(key: _setupCompletedKey);
    return value == 'true';
  }

  static Future<void> setSetupCompleted() async {
    await _storage.write(key: _setupCompletedKey, value: 'true');
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _completedKey);
    await _storage.delete(key: _agreedKey);
    await _storage.delete(key: _lastVersionKey);
    await _storage.delete(key: _setupCompletedKey);
  }

  /// Check if there's a new version the user hasn't seen yet
  static Future<bool> hasNewVersion() async {
    final lastSeen = await getLastSeenVersion();
    return lastSeen != currentVersion;
  }

  /// Show "What's New" dialog if app was updated
  static Future<void> showWhatsNewIfNeeded(BuildContext context) async {
    if (!await hasNewVersion()) return;
    if (!context.mounted) return;

    final changes = _changelogs[currentVersion] ?? [];
    if (changes.isEmpty) return;

    await setLastSeenVersion(currentVersion);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => _WhatsNewDialog(
        version: currentVersion,
        changes: changes,
      ),
    );
  }
}

class _WhatsNewDialog extends StatelessWidget {
  final String version;
  final List<String> changes;

  const _WhatsNewDialog({
    required this.version,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 30,
                color: context.appPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "What's New",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.appOnSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version $version',
              style: TextStyle(
                fontSize: 13,
                color: context.appOnSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),

            // Changes list
            ...changes.map((change) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: context.appSuccess,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          change,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.appOnSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
