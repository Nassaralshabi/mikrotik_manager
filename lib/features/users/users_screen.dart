import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key, required this.repository});

  final BackendRepository repository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<UserProfile>>(
        future: repository.profiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingStateView();
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final users = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'إدارة المشتركين (${users.length})',
                action: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('إضافة عميل'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final statusColor = user.isSuspended ? Colors.red : Colors.green;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 28, child: Text(user.name.characters.first)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                                  Text('الباقة: ${user.plan}'),
                                  Text('الرصيد: ${user.balance.toStringAsFixed(2)} ر.س'),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('جلسات ${user.activeSessions}'),
                                Chip(
                                  label: Text(user.isSuspended ? 'موقوف' : 'نشط'),
                                  backgroundColor: statusColor.withOpacity(.15),
                                  labelStyle: TextStyle(color: statusColor),
                                ),
                                TextButton(onPressed: () {}, child: const Text('تفاصيل')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
