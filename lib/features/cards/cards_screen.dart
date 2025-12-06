import 'package:flutter/material.dart';

import '../../data/models/service_card.dart';
import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key, required this.repository});

  final BackendRepository repository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<ServiceCard>>(
        future: repository.cards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingStateView();
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final cards = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'البطاقات (${cards.length})',
                action: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_card),
                  label: const Text('طرح باقة'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final statusColor = card.status.contains('موقوف') ? Colors.red : Colors.green;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.title, style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            Text('السعة: ${card.quota}'),
                            Text('السعر: ${card.price.toStringAsFixed(2)} ر.س'),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(card.status),
                              backgroundColor: statusColor.withOpacity(.12),
                              labelStyle: TextStyle(color: statusColor),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: OutlinedButton(onPressed: () {}, child: const Text('إدارة البطاقة')),
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
