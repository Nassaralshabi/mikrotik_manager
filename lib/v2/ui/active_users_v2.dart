import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/active_users_provider.dart';

class ActiveUsersV2 extends ConsumerWidget {
  const ActiveUsersV2({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeUsersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون النشطون V2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.loading ? null : () => ref.read(activeUsersProvider.notifier).fetch(),
          )
        ],
      ),
      body: state.loading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(state.hotspot ? 'Hotspot' : 'User Manager'),
                      const Spacer(),
                      Text(state.serverPaging ? 'Server Paging' : 'Local Paging'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final u = state.items[index];
                      final name = u['user'] ?? u['name'] ?? '-';
                      final ip = u['address'] ?? u['framed-ip-address'] ?? '-';
                      final up = u['uptime'] ?? u['session-time-left'] ?? '';
                      return ListTile(
                        title: Text('$name'),
                        subtitle: Text('$ip • $up'),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: state.page > 0 && !state.loading ? () => ref.read(activeUsersProvider.notifier).prevPage() : null,
                      child: const Text('السابق'),
                    ),
                    const SizedBox(width: 12),
                    Text('صفحة ${state.page + 1}'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: !state.loading ? () => ref.read(activeUsersProvider.notifier).nextPage() : null,
                      child: const Text('التالي'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }
}