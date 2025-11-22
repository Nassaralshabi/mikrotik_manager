import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router_service.dart';

class CardsStatsState {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> sessions;
  final bool loading;
  final String? error;
  CardsStatsState({required this.users, required this.sessions, required this.loading, required this.error});
  CardsStatsState copyWith({List<Map<String, dynamic>>? users, List<Map<String, dynamic>>? sessions, bool? loading, String? error}) => CardsStatsState(users: users ?? this.users, sessions: sessions ?? this.sessions, loading: loading ?? this.loading, error: error);
  static CardsStatsState initial() => CardsStatsState(users: const [], sessions: const [], loading: false, error: null);
}

class CardsStatsNotifier extends StateNotifier<CardsStatsState> {
  CardsStatsNotifier({this.maxRecords = 50, this.chunk = 20}) : super(CardsStatsState.initial());
  final int maxRecords;
  final int chunk;
  final _service = RouterService();

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final users = await _fetchPaginated('/tool/user-manager/user/print', 'username,disabled,upload-used,download-used,actual-profile,uptime-limit,uptime-used');
      final sessions = await _fetchPaginated('/tool/user-manager/session/print', 'user,upload,download,uptime,start-time');
      state = state.copyWith(users: users, sessions: sessions, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPaginated(String path, String proplist) async {
    final all = <Map<String, dynamic>>[];
    int skip = 0;
    while (all.length < maxRecords) {
      try {
        final res = await _service.talkPaged(path: path, proplist: proplist, limit: chunk, skip: skip);
        all.addAll(res);
        if (res.length < chunk) break;
        skip += chunk;
      } catch (_) {
        final res = await _service.talk([path, '=.proplist=$proplist']);
        all.addAll(res);
        break;
      }
    }
    if (all.length > maxRecords) {
      return all.sublist(0, maxRecords);
    }
    return all;
  }
}

final cardsStatsProvider = StateNotifierProvider<CardsStatsNotifier, CardsStatsState>((ref) => CardsStatsNotifier(maxRecords: 50, chunk: 20));