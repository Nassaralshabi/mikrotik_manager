import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/search_service.dart';

class GlobalSearchDelegate extends SearchDelegate<String?> {
  final BuildContext context;

  GlobalSearchDelegate(this.context);

  @override
  String get searchFieldLabel => 'Search...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = query.isEmpty
        ? GlobalSearchActions.getAllActions()
        : GlobalSearchActions.search(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final action = results[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              action.icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(action.title),
          subtitle: Text(action.subtitle),
          onTap: () {
            if (query.isNotEmpty) {
              SearchService.addRecentSearch(query);
            }
            close(context, action.route);
            context.go(action.route);
          },
        );
      },
    );
  }
}

void showGlobalSearch(BuildContext context) {
  showSearch(
    context: context,
    delegate: GlobalSearchDelegate(context),
  );
}
