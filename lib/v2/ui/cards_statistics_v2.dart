import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cards_stats_provider.dart';

class CardsStatisticsV2 extends ConsumerWidget {
  const CardsStatisticsV2({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cardsStatsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات الكروت V2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: s.loading ? null : () => ref.read(cardsStatsProvider.notifier).fetch(),
          )
        ],
      ),
      body: s.loading && s.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('عدد المستخدمين'),
                    trailing: Text('${s.users.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('عدد الجلسات'),
                    trailing: Text('${s.sessions.length}'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('عينة مستخدمين'),
                ...s.users.take(10).map((u) => ListTile(title: Text('${u['username'] ?? '-'}'), subtitle: Text('${u['actual-profile'] ?? '-'}'))),
              ],
            ),
    );
  }
}