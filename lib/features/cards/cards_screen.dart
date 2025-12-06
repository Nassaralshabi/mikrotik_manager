import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/service_card.dart';
import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';
import 'cards_screen_helper.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key, required this.repository});

  final BackendRepository repository;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> with CardsScreenHelper {
  Future<List<ServiceCard>> _cardsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _refreshCards();
  }

  void _refreshCards() {
    setState(() {
      _cardsFuture = widget.repository.cards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<ServiceCard>>(
        future: _cardsFuture,
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
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showFinishedCards(context),
                      icon: const Icon(Icons.list),
                      label: const Text('البطاقات المنتهية'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => openFilesManager(context),
                      icon: const Icon(Icons.folder),
                      label: const Text('ملفات PDF'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => showAddCardDialog(context, widget.repository, _refreshCards),
                      icon: const Icon(Icons.add_card),
                      label: const Text('إضافة بطاقات'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final statusColor = card.status.contains('موقوف') ? Colors.red : Colors.green;
                    return Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    card.title, 
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) => handleCardAction(context, value, card, widget.repository, _refreshCards),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'print', child: Text('طباعة البطاقة')),
                                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                card.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('السعة: ${card.quota}', style: const TextStyle(fontSize: 13)),
                            Text('السعر: ${card.price.toStringAsFixed(2)} ر.س', style: const TextStyle(fontSize: 13)),
                            if (card.username != null)
                              Text('المستخدم: ${card.username}', 
                                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => printCard(context, card),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('طباعة', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => manageCard(context, card, widget.repository, _refreshCards),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('إدارة', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
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