import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/models.dart';

final smartConnectionsProvider = StateNotifierProvider<SmartConnectionsNotifier, List<RouterConnection>>((ref) {
  return SmartConnectionsNotifier();
});

class SmartConnectionsNotifier extends StateNotifier<List<RouterConnection>> {
  SmartConnectionsNotifier() : super([]);

  void refreshConnections() {
    // In a real implementation, this would fetch connections from the service
    // For now, it's a placeholder that would be implemented based on your data source
    state = state;
  }

  void addConnection(RouterConnection connection) {
    state = [...state, connection];
  }

  void deleteConnection(RouterConnection connection) {
    state = state.where((c) => c.id != connection.id).toList();
  }

  void updateConnection(RouterConnection updatedConnection) {
    state = state.map((c) => c.id == updatedConnection.id ? updatedConnection : c).toList();
  }
}
