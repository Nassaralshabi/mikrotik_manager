import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SearchService {
  static const String _boxName = 'search_history';
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 5;
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static List<String> getRecentSearches() {
    if (_box == null) return [];
    final searches = _box!.get(_recentSearchesKey, defaultValue: <String>[]);
    return List<String>.from(searches);
  }

  static Future<void> addRecentSearch(String query) async {
    if (_box == null || query.trim().isEmpty) return;

    final searches = getRecentSearches();
    searches.remove(query);
    searches.insert(0, query);

    if (searches.length > _maxRecentSearches) {
      searches.removeRange(_maxRecentSearches, searches.length);
    }

    await _box!.put(_recentSearchesKey, searches);
  }

  static Future<void> clearRecentSearches() async {
    await _box?.delete(_recentSearchesKey);
  }

  static Future<void> removeRecentSearch(String query) async {
    final searches = getRecentSearches();
    searches.remove(query);
    await _box?.put(_recentSearchesKey, searches);
  }
}

class SearchAction {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;

  const SearchAction({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });
}

class GlobalSearchActions {
  static List<SearchAction> getAllActions() {
    return [
      SearchAction(
        title: 'Dashboard',
        subtitle: 'View dashboard overview',
        route: '/main/dashboard',
        icon: Icons.dashboard_rounded,
      ),
      SearchAction(
        title: 'Hotspot Users',
        subtitle: 'Manage hotspot users',
        route: '/main/users',
        icon: Icons.people_rounded,
      ),
      SearchAction(
        title: 'Create Vouchers',
        subtitle: 'Generate new vouchers',
        route: '/main/vouchers/generate',
        icon: Icons.add_card_rounded,
      ),
      SearchAction(
        title: 'Vouchers List',
        subtitle: 'View all vouchers',
        route: '/main/vouchers',
        icon: Icons.confirmation_number_rounded,
      ),
      SearchAction(
        title: 'User Profiles',
        subtitle: 'Manage user profiles',
        route: '/main/profiles',
        icon: Icons.card_membership_rounded,
      ),
      SearchAction(
        title: 'Hotspot Hosts',
        subtitle: 'View connected hosts',
        route: '/main/hosts',
        icon: Icons.lan_rounded,
      ),
      SearchAction(
        title: 'DHCP Leases',
        subtitle: 'View device leases',
        route: '/main/dhcp-leases',
        icon: Icons.devices_rounded,
      ),
      SearchAction(
        title: 'Active Users',
        subtitle: 'View active sessions',
        route: '/main/active',
        icon: Icons.wifi_rounded,
      ),
      SearchAction(
        title: 'Revenue',
        subtitle: 'View income reports',
        route: '/main/revenue',
        icon: Icons.payments_rounded,
      ),
      SearchAction(
        title: 'Activity Logs',
        subtitle: 'View activity history',
        route: '/main/logs',
        icon: Icons.history_rounded,
      ),
      SearchAction(
        title: 'Settings',
        subtitle: 'App settings',
        route: '/main/settings',
        icon: Icons.settings_rounded,
      ),
    ];
  }

  static List<SearchAction> search(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return getAllActions().where((action) {
      return action.title.toLowerCase().contains(lowerQuery) ||
          action.subtitle.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
