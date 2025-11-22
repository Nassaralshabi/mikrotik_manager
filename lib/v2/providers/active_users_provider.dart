import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router_service.dart';

class ActiveUsersState {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final String? error;
  final bool hotspot;
  final bool serverPaging;
  final int page;
  final int pageSize;
  ActiveUsersState({
    required this.items,
    required this.loading,
    required this.error,
    required this.hotspot,
    required this.serverPaging,
    required this.page,
    required this.pageSize,
  });
  ActiveUsersState copyWith({
    List<Map<String, dynamic>>? items,
    bool? loading,
    String? error,
    bool? hotspot,
    bool? serverPaging,
    int? page,
    int? pageSize,
  }) => ActiveUsersState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    error: error,
    hotspot: hotspot ?? this.hotspot,
    serverPaging: serverPaging ?? this.serverPaging,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
  );
  static ActiveUsersState initial(int pageSize) => ActiveUsersState(items: const [], loading: false, error: null, hotspot: true, serverPaging: false, page: 0, pageSize: pageSize);
}

class ActiveUsersNotifier extends StateNotifier<ActiveUsersState> {
  ActiveUsersNotifier({this.pageSize = 20}) : super(ActiveUsersState.initial(pageSize));
  final int pageSize;
  final _service = RouterService();

  Future<void> fetch({int? page}) async {
    state = state.copyWith(loading: true, error: null, page: page ?? state.page);
    final p = state.page;
    try {
      try {
        final res = await _service.talkPaged(
          path: '/ip/hotspot/active/print',
          proplist: 'user,address,uptime',
          limit: pageSize,
          skip: p * pageSize,
        );
        state = state.copyWith(items: res, hotspot: true, serverPaging: true, loading: false);
        return;
      } catch (_) {}
      final resHot = await _service.talk(['/ip/hotspot/active/print', '=.proplist=user,address,uptime']);
      state = state.copyWith(items: resHot, hotspot: true, serverPaging: false, loading: false);
    } catch (_) {
      try {
        final res = await _service.talkPaged(
          path: '/tool/user-manager/session/print',
          proplist: 'user,session-time-left,framed-ip-address,uptime',
          limit: pageSize,
          skip: p * pageSize,
        );
        state = state.copyWith(items: res, hotspot: false, serverPaging: true, loading: false);
      } catch (_) {
        final res = await _service.talk(['/tool/user-manager/session/print', '=.proplist=user,session-time-left,framed-ip-address,uptime']);
        state = state.copyWith(items: res, hotspot: false, serverPaging: false, loading: false);
      }
    }
  }

  void nextPage() {
    state = state.copyWith(page: state.page + 1);
    fetch();
  }
  void prevPage() {
    if (state.page == 0) return;
    state = state.copyWith(page: state.page - 1);
    fetch();
  }
}

final activeUsersProvider = StateNotifierProvider<ActiveUsersNotifier, ActiveUsersState>((ref) => ActiveUsersNotifier(pageSize: 20));