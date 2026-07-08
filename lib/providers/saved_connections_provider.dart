import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/models.dart';

final savedConnectionsProvider = StateNotifierProvider<ConnectionsNotifier, List<RouterConnection>>((ref) {
  return ConnectionsNotifier();
});

class ConnectionsNotifier extends StateNotifier<List<RouterConnection>> {
  ConnectionsNotifier() : super([]);

  void addConnection(RouterConnection connection) {
    state = [...state, connection];
  }

  void removeConnection(RouterConnection connection) {
    state = state.where((c) => c.id != connection.id).toList();
  }

  void updateConnection(RouterConnection updatedConnection) {
    state = state.map((c) => c.id == updatedConnection.id ? updatedConnection : c).toList();
  }
}
