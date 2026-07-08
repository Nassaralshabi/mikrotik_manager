import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../l10n/translations.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  static const String _formUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSc4y5k40sMypISeOszwHkAGY5VQNOJgoOz7WM_14knVJgtXiQ/viewform';

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_formUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).feedbackFailed),
            backgroundColor: context.appError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/main'),
          tooltip: AppStrings.of(context).back,
        ),
        title: Text(
          AppStrings.of(context).sendFeedback,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.feedback_rounded,
              size: 48,
              color: context.appPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.of(context).sendFeedback,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve the app by sharing your thoughts, suggestions, or reporting issues.',
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.appPrimary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.open_in_browser_rounded,
                    size: 56,
                    color: context.appPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).openInBrowser,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.appOnSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your browser will open to submit feedback via Google Forms',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appOnSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: Text(
                  AppStrings.of(context).openInBrowser,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
