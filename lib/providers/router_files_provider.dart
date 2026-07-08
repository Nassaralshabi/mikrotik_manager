import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mikrotik_client.dart';
import '../services/routeros_service.dart';

final _routerOSServiceProvider = Provider<RouterOSService>((ref) {
  return RouterOSService();
});

Provider<RouterOSService> get routerOSServiceProvider => _routerOSServiceProvider;

class RouterFile {
  final String id;
  final String name;
  final String? type;
  final int? size;
  final DateTime? created;
  final String? path;

  RouterFile({
    required this.id,
    required this.name,
    this.type,
    this.size,
    this.created,
    this.path,
  });

  factory RouterFile.fromJson(Map<String, dynamic> json) {
    String? parsedSize;
    if (json['size'] is String) {
      parsedSize = json['size'];
    } else if (json['size'] is int) {
      parsedSize = json['size'].toString();
    }

    return RouterFile(
      id: json['.id'] ?? json['name'] ?? '',
      name: json['name'] ?? 'Unknown',
      type: json['type'],
      size: parsedSize != null ? int.tryParse(parsedSize) : null,
      created: json['creation-time'] != null
          ? DateTime.tryParse(json['creation-time'].toString())
          : null,
      path: json['path'],
    );
  }

  String get sizeDisplay {
    if (size == null || size == 0) return '-';
    final bytes = size!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  bool get isBackup => name.endsWith('.backup') || name.endsWith('.rsc');
  bool get isConfig => name.endsWith('.rsc');
  bool get isBackupFile => name.endsWith('.backup');

  IconData get icon {
    if (isBackup || isBackupFile) return Icons.backup_rounded;
    if (isConfig) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }
}

class RouterFilesState {
  final List<RouterFile> files;
  final bool isLoading;
  final String? error;
  final bool isCreatingBackup;
  final bool isExporting;

  const RouterFilesState({
    this.files = const [],
    this.isLoading = false,
    this.error,
    this.isCreatingBackup = false,
    this.isExporting = false,
  });

  RouterFilesState copyWith({
    List<RouterFile>? files,
    bool? isLoading,
    String? error,
    bool? isCreatingBackup,
    bool? isExporting,
  }) {
    return RouterFilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCreatingBackup: isCreatingBackup ?? this.isCreatingBackup,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  List<RouterFile> get backups =>
      files.where((f) => f.isBackup || f.isBackupFile).toList();
  List<RouterFile> get configs =>
      files.where((f) => f.isConfig && !f.isBackup).toList();
  List<RouterFile> get others =>
      files.where((f) => !f.isBackup && !f.isConfig && !f.isBackupFile).toList();
  List<RouterFile> get filesList => files;
}

class RouterFilesNotifier extends StateNotifier<RouterFilesState> {
  final Ref _ref;

  RouterFilesNotifier(this._ref) : super(const RouterFilesState());

  MikrotikClient? get _client => _ref.read(routerOSServiceProvider).client;

  Future<void> loadFiles() async {
    if (_client == null) {
      state = state.copyWith(error: 'Not connected to RouterOS');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _client!.getFiles();
      final files = data.map((json) => RouterFile.fromJson(json)).toList();
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load files: $e',
      );
    }
  }

  Future<bool> deleteFile(RouterFile file) async {
    try {
      await _client!.deleteFile(file.id);
      state = state.copyWith(
        files: state.files.where((f) => f.id != file.id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete file: $e');
      return false;
    }
  }

  Future<bool> createBackup(String name) async {
    state = state.copyWith(isCreatingBackup: true, error: null);

    try {
      await _client!.createBackup(name);
      await loadFiles();
      state = state.copyWith(isCreatingBackup: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreatingBackup: false,
        error: 'Failed to create backup: $e',
      );
      return false;
    }
  }

  Future<bool> exportConfig(String name) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      await _client!.exportConfig(name);
      await loadFiles();
      state = state.copyWith(isExporting: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to export config: $e',
      );
      return false;
    }
  }

  Future<String?> downloadFile(RouterFile file) async {
    try {
      final content = await _client!.downloadFile(file.name);
      return content;
    } catch (e) {
      state = state.copyWith(error: 'Failed to download file: $e');
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final routerFilesProvider =
    StateNotifierProvider<RouterFilesNotifier, RouterFilesState>((ref) {
  return RouterFilesNotifier(ref);
});