import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/router_files_provider.dart';
import '../../l10n/translations.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routerFilesProvider.notifier).loadFiles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(routerFilesProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        title: Text(
          AppStrings.of(context).files,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(routerFilesProvider.notifier).loadFiles(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.appPrimary,
          unselectedLabelColor:
              context.appOnSurface.withValues(alpha: 0.6),
          indicatorColor: context.appPrimary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Backups'),
            Tab(text: 'Exports'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildQuickActions(filesState),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFileList(filesState.files),
                _buildFileList(filesState.backups),
                _buildFileList(filesState.configs),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBackupDialog,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        child: const Icon(Icons.backup_rounded),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.glassmorphismDecoration(
        surfaceColor: context.appSurface,
        onSurfaceColor: context.appOnSurface,
        borderRadius: 16,
      ),
      child: TextField(
        onChanged: (value) =>
            setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search files...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(RouterFilesState state) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.backup_rounded,
              label: 'New Backup',
              color: const Color(0xFF10B981),
              isLoading: state.isCreatingBackup,
              onTap: () => _showCreateBackupDialog(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.code_rounded,
              label: 'Export Config',
              color: const Color(0xFF8B5CF6),
              isLoading: state.isExporting,
              onTap: () => _showExportConfigDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: AppTheme.glassmorphismDecoration(
          surfaceColor: color.withValues(alpha: 0.15),
          onSurfaceColor: color,
          borderRadius: 16,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFileList(List<RouterFile> files) {
    final filteredFiles = _searchQuery.isEmpty
        ? files
        : files
            .where((f) =>
                f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (filteredFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: context.appOnSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No files found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(routerFilesProvider.notifier).loadFiles(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: filteredFiles.length,
        itemBuilder: (context, index) {
          final file = filteredFiles[index];
          return _buildFileCard(file);
        },
      ),
    );
  }

  Widget _buildFileCard(RouterFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassmorphismDecoration(
        surfaceColor: context.appSurface,
        onSurfaceColor: context.appOnSurface,
        borderRadius: 12,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getFileColor(file).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            file.icon,
            color: _getFileColor(file),
            size: 24,
          ),
        ),
        title: Text(
          file.name,
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  file.sizeDisplay,
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                if (file.created != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: context.appOnSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(file.created!),
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: context.appOnSurface.withValues(alpha: 0.6),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'download',
              child: const Row(
                children: [
                  Icon(Icons.download_rounded),
                  SizedBox(width: 12),
                  Text('Download'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'copy',
              child: const Row(
                children: [
                  Icon(Icons.copy_rounded),
                  SizedBox(width: 12),
                  Text('Copy Content'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded,
                      color: context.appError),
                  const SizedBox(width: 12),
                  Text('Delete',
                      style: TextStyle(color: context.appError)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              await _confirmDelete(file);
            } else if (value == 'download') {
              await _downloadFile(file);
            } else if (value == 'copy') {
              await _copyFileContent(file);
            }
          },
        ),
      ),
    );
  }

  Color _getFileColor(RouterFile file) {
    if (file.isBackup || file.isBackupFile) {
      return const Color(0xFF10B981);
    }
    if (file.isConfig) {
      return const Color(0xFF8B5CF6);
    }
    return context.appPrimary;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat.Hm().format(date);
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  Future<void> _confirmDelete(RouterFile file) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(routerFilesProvider.notifier).deleteFile(file);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.appError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(RouterFile file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Downloading...'),
          ],
        ),
      ),
    );

    try {
      final content = await ref.read(routerFilesProvider.notifier).downloadFile(file);
      if (mounted) Navigator.pop(context);

      if (content != null && content.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${file.name} content copied to clipboard'),
              backgroundColor: context.appSuccess,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download ${file.name}'),
              backgroundColor: context.appError,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.appError,
          ),
        );
      }
    }
  }

  Future<void> _copyFileContent(RouterFile file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Loading...'),
          ],
        ),
      ),
    );

    try {
      final content = await ref.read(routerFilesProvider.notifier).downloadFile(file);
      if (mounted) Navigator.pop(context);

      if (content != null && content.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Content copied to clipboard'),
              backgroundColor: context.appSuccess,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Empty or unable to read ${file.name}'),
              backgroundColor: context.appWarning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.appError,
          ),
        );
      }
    }
  }

  Future<void> _showCreateBackupDialog() {
    final controller = TextEditingController(
      text: 'backup-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Backup Name',
                hintText: 'e.g., backup-20240101',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This backup is hardware-locked and can only be restored on this router. '
                      'To migrate to a different device, use "Export Config" instead.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(routerFilesProvider.notifier).createBackup(controller.text);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup created: ${controller.text}'),
                      backgroundColor: context.appSuccess,
                    ),
                  );
                } else {
                  final error = ref.read(routerFilesProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to create backup'),
                      backgroundColor: context.appError,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportConfigDialog() {
    final controller = TextEditingController(
      text: 'config-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'File Name',
                hintText: 'e.g., config-20240101',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exported as a plain-text script (.rsc). '
                      'Can be imported to any RouterOS device for cross-device migration.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(routerFilesProvider.notifier).exportConfig(controller.text);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Configuration exported: ${controller.text}'),
                      backgroundColor: context.appSuccess,
                    ),
                  );
                } else {
                  final error = ref.read(routerFilesProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to export configuration'),
                      backgroundColor: context.appError,
                    ),
                  );
                }
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
