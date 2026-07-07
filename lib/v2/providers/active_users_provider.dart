// ============================================================
//  ActiveUsersProvider — V2 محسّن مع AppResult + MikrotikRepository
//
//  التحسينات:
//  1. يستخدم IMikrotikRepository بدل RouterService
//  2. يستخدم AppResult<T> لنمط Success/Failure/Loading
//  3. const constructor للـ State
//  4. select() + cache + autoDispose
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/mikrotik_repository.dart';
import '../../core/errors/app_result.dart';
import 'optimized_providers.dart';

/// State مع const constructor
class ActiveUsersState {
  final List<Map<String, dynamic>> items;
  final AppResult<List<Map<String, dynamic>>> result;
  final bool hotspot;
  final bool serverPaging;
  final int page;
  final int pageSize;

  const ActiveUsersState({
    required this.items,
    required this.result,
    required this.hotspot,
    required this.serverPaging,
    required this.page,
    required this.pageSize,
  });

  ActiveUsersState copyWith({
    List<Map<String, dynamic>>? items,
    AppResult<List<Map<String, dynamic>>>? result,
    bool? hotspot,
    bool? serverPaging,
    int? page,
    int? pageSize,
  }) =>
      ActiveUsersState(
        items: items ?? this.items,
        result: result ?? this.result,
        hotspot: hotspot ?? this.hotspot,
        serverPaging: serverPaging ?? this.serverPaging,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );

  static ActiveUsersState initial(int pageSize) => ActiveUsersState(
        items: const [],
        result: const AppLoading(stage: 'idle'),
        hotspot: true,
        serverPaging: false,
        page: 0,
        pageSize: pageSize,
      );
}

/// Notifier محسّن:
/// - يستخدم IMikrotikRepository (Riverpod DI)
/// - ResponseCache لتجنّب إعادة الجلب
/// - AppResult للحالات الثلاث
class ActiveUsersNotifier extends StateNotifier<ActiveUsersState> {
  ActiveUsersNotifier(this._ref, {this.pageSize = 20})
      : super(ActiveUsersState.initial(pageSize));

  final Ref _ref;
  final int pageSize;

  IMikrotikRepository get _repo => _ref.read(mikrotikRepositoryProvider);

  String _cacheKey(int p) => 'active_users_p$p';

  Future<void> fetch({int? page}) async {
    final targetPage = page ?? state.page;
    final cache = _ref.read(responseCacheProvider);
    final cached = cache.get(_cacheKey(targetPage));

    if (cached != null) {
      state = state.copyWith(items: cached, page: targetPage, result: AppSuccess(cached));
      return;
    }

    // Show loading only if list is empty (avoid flicker)
    if (state.items.isEmpty) {
      state = state.copyWith(
        page: targetPage,
        result: const AppLoading(stage: 'جاري التحميل...'),
      );
    }

    try {
      // Try hotspot with paging first
      try {
        final res = await _repo.talkPaged(
          path: '/ip/hotspot/active/print',
          proplist: 'user,address,uptime',
          limit: pageSize,
          skip: targetPage * pageSize,
        );
        cache.put(_cacheKey(targetPage), res);
        state = state.copyWith(
          items: res,
          hotspot: true,
          serverPaging: true,
          page: targetPage,
          result: AppSuccess(res),
        );
        return;
      } catch (_) {}

      // Fallback to hotspot without paging
      final resHot = await _repo.talk([
        '/ip/hotspot/active/print',
        '=.proplist=user,address,uptime',
      ]);
      cache.put(_cacheKey(targetPage), resHot);
      state = state.copyWith(
        items: resHot, hotspot: true, serverPaging: false,
        page: targetPage, result: AppSuccess(resHot),
      );
    } catch (e) {
      // Fallback to user-manager
      try {
        final res = await _repo.talkPaged(
          path: '/tool/user-manager/session/print',
          proplist: 'user,session-time-left,framed-ip-address,uptime',
          limit: pageSize, skip: targetPage * pageSize,
        );
        cache.put(_cacheKey(targetPage), res);
        state = state.copyWith(
          items: res, hotspot: false, serverPaging: true,
          page: targetPage, result: AppSuccess(res),
        );
      } catch (e) {
        state = state.copyWith(
          page: targetPage,
          result: AppFailure('فشل تحميل المستخدمين النشطين', cause: e),
        );
      }
    }
  }

  void nextPage() {
    final p = state.page + 1;
    state = state.copyWith(page: p);
    fetch(page: p);
  }

  void prevPage() {
    if (state.page == 0) return;
    final p = state.page - 1;
    state = state.copyWith(page: p);
    fetch(page: p);
  }

  void refresh() {
    final cache = _ref.read(responseCacheProvider);
    cache.invalidate(_cacheKey(state.page));
    fetch();
  }
}

final activeUsersProvider =
    StateNotifierProvider<ActiveUsersNotifier, ActiveUsersState>(
  (ref) => ActiveUsersNotifier(ref, pageSize: 20),
);
