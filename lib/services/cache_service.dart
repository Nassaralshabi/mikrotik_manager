import 'package:hive_flutter/hive_flutter.dart';

/// Cache service for storing RouterOS data locally using Hive
/// Provides instant data access and offline support
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late Box _cacheBox;
  bool _initialized = false;

  // Cache keys
  static const String _boxName = 'routeros_cache';
  static const String _systemResourcesKey = 'system_resources';
  static const String _hotspotUsersKey = 'hotspot_users';
  static const String _activeUsersKey = 'active_users';
  static const String _userProfilesKey = 'user_profiles';
  static const String _salesTransactionsKey = 'sales_transactions';
  static const String _incomeSummaryKey = 'income_summary';
  static const String _savedConnectionsKey = 'saved_connections';
  static const String _lastUpdateKey = 'last_update';
  static const String _interfaceTrafficKey = 'interface_traffic';
  static const String _vouchersKey = 'generated_vouchers';
  static const String _appSettingsKey = 'app_settings';
  static const String _recordedConnectionsKey = 'recorded_connections';
  static const String _profilePricesKey = 'profile_prices_map';

  /// Initialize Hive cache
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Open cache box
      _cacheBox = await Hive.openBox(_boxName);

      _initialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if cache is initialized
  bool get isInitialized => _initialized;

  /// Get persistent profile prices map {profileName: price}
  Map<String, double> getProfilePrices() {
    try {
      final data = _cacheBox.get(_profilePricesKey);
      if (data != null && data is Map) {
        return Map<String, double>.from(data.map((key, value) => MapEntry(key.toString(), (value as num).toDouble())));
      }
    } catch (e) {}
    return {};
  }

  /// Save profile price to persistent map
  Future<void> saveProfilePrice(String profileName, double price) async {
    try {
      final map = getProfilePrices();
      map[profileName] = price;
      await _cacheBox.put(_profilePricesKey, map);
    } catch (e) {}
  }

  /// Get system resources from cache
  Map<String, dynamic>? getSystemResources() {
    try {
      final data = _cacheBox.get(_systemResourcesKey);
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save system resources to cache
  Future<void> saveSystemResources(Map<String, dynamic> data) async {
    try {
      await _cacheBox.put(_systemResourcesKey, data);
      await _cacheBox.put(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Error saving
    }
  }

  /// Get hotspot users from cache
  List<Map<String, dynamic>>? getHotspotUsers() {
    try {
      final data = _cacheBox.get(_hotspotUsersKey);
      if (data != null && data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save hotspot users to cache
  Future<void> saveHotspotUsers(List<Map<String, dynamic>> data) async {
    try {
      await _cacheBox.put(_hotspotUsersKey, data);
    } catch (e) {
      // Error saving
    }
  }

  /// Get active users from cache
  List<Map<String, dynamic>>? getActiveUsers() {
    try {
      final data = _cacheBox.get(_activeUsersKey);
      if (data != null && data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save active users to cache
  Future<void> saveActiveUsers(List<Map<String, dynamic>> data) async {
    try {
      await _cacheBox.put(_activeUsersKey, data);
    } catch (e) {
      // Error saving
    }
  }

  /// Get user profiles from cache
  List<Map<String, dynamic>>? getUserProfiles() {
    try {
      final data = _cacheBox.get(_userProfilesKey);
      if (data != null && data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save user profiles to cache
  Future<void> saveUserProfiles(List<Map<String, dynamic>> data) async {
    try {
      await _cacheBox.put(_userProfilesKey, data);
    } catch (e) {
      // Error saving
    }
  }

  /// Get sales transactions from cache
  List<Map<String, dynamic>>? getSalesTransactions() {
    try {
      final data = _cacheBox.get(_salesTransactionsKey);
      if (data != null && data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save a single sales transaction to cache
  Future<void> saveSalesTransaction(Map<String, dynamic> transaction) async {
    try {
      final transactions = getSalesTransactions() ?? [];
      transactions.add(transaction);
      await _cacheBox.put(_salesTransactionsKey, transactions);
    } catch (e) {
      // Error saving
    }
  }

  /// Save multiple sales transactions to cache
  Future<void> saveSalesTransactions(
      List<Map<String, dynamic>> transactions) async {
    try {
      await _cacheBox.put(_salesTransactionsKey, transactions);
    } catch (e) {
      // Error saving
    }
  }

  /// Get income summary from cache
  Map<String, dynamic>? getIncomeSummary() {
    try {
      final data = _cacheBox.get(_incomeSummaryKey);
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save income summary to cache
  Future<void> saveIncomeSummary(Map<String, dynamic> summary) async {
    try {
      await _cacheBox.put(_incomeSummaryKey, summary);
    } catch (e) {
      // Error saving
    }
  }

  /// Get recorded connections (for income tracking - only record once per session)
  Set<String> getRecordedConnections() {
    try {
      final data = _cacheBox.get(_recordedConnectionsKey);
      if (data != null && data is List) {
        return data.map((e) => e.toString()).toSet();
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Save recorded connections to cache
  Future<void> saveRecordedConnections(Set<String> connections) async {
    try {
      await _cacheBox.put(_recordedConnectionsKey, connections.toList());
    } catch (e) {
      // Error saving
    }
  }

  /// Get saved router connections from cache
  List<Map<String, dynamic>>? getSavedConnections() {
    try {
      final data = _cacheBox.get(_savedConnectionsKey);
      if (data != null && data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save router connections to cache
  Future<void> saveSavedConnections(
      List<Map<String, dynamic>> connections) async {
    try {
      await _cacheBox.put(_savedConnectionsKey, connections);
    } catch (e) {
      // Error saving
    }
  }

  /// Add a single router connection to cache
  Future<void> addSavedConnection(Map<String, dynamic> connection) async {
    try {
      final connections = getSavedConnections() ?? [];
      connections.add(connection);
      await _cacheBox.put(_savedConnectionsKey, connections);
    } catch (e) {
      // Error adding
    }
  }

  /// Update a router connection in cache
  Future<void> updateSavedConnection(
      String id, Map<String, dynamic> updatedConnection) async {
    try {
      final connections = getSavedConnections();
      if (connections == null) return;

      final index = connections.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        connections[index] = updatedConnection;
        await _cacheBox.put(_savedConnectionsKey, connections);
      }
    } catch (e) {
      // Error updating
    }
  }

  /// Delete a router connection from cache
  Future<void> deleteSavedConnection(String id) async {
    try {
      final connections = getSavedConnections();
      if (connections == null) return;

      connections.removeWhere((c) => c['id'] == id);
      await _cacheBox.put(_savedConnectionsKey, connections);
    } catch (e) {
      // Error deleting
    }
  }

  /// Get last update timestamp
  DateTime? getLastUpdate() {
    try {
      final timestamp = _cacheBox.get(_lastUpdateKey);
      if (timestamp != null && timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is stale (older than specified duration)
  bool isCacheStale({Duration maxAge = const Duration(minutes: 5)}) {
    final lastUpdate = getLastUpdate();
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate) > maxAge;
  }

  /// Clear operational cached data but preserve persistent settings
  Future<void> clearCache() async {
    try {
      // List of keys to preserve
      final persistentKeys = [
        _savedConnectionsKey,
        _appSettingsKey,
        _salesTransactionsKey,
        _profilePricesKey,
        _vouchersKey,
      ];

      final allKeys = _cacheBox.keys.toList();
      for (final key in allKeys) {
        if (!persistentKeys.contains(key)) {
          await _cacheBox.delete(key);
        }
      }
    } catch (e) {
      // Error clearing
    }
  }

  /// Clear specific cache entry
  Future<void> clearEntry(String key) async {
    try {
      await _cacheBox.delete(key);
    } catch (e) {
      // Error clearing
    }
  }

  /// Close the cache box
  Future<void> close() async {
    try {
      await _cacheBox.close();
      _initialized = false;
    } catch (e) {
      // Error closing
    }
  }

  /// Get interface traffic from cache
  List<Map<String, dynamic>>? getInterfaceTraffic() {
    try {
      final data = _cacheBox.get(_interfaceTrafficKey);
      if (data != null && data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save interface traffic to cache
  Future<void> saveInterfaceTraffic(List<Map<String, dynamic>> data) async {
    try {
      await _cacheBox.put(_interfaceTrafficKey, data);
    } catch (e) {
      // Error saving
    }
  }

  /// Get generated vouchers from cache
  List<Map<String, dynamic>>? getVouchers() {
    try {
      final data = _cacheBox.get(_vouchersKey);
      if (data != null && data is List) {
        return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save vouchers to cache
  Future<void> saveVouchers(List<Map<String, dynamic>> vouchers) async {
    try {
      await _cacheBox.put(_vouchersKey, vouchers);
    } catch (e) {
      // Error saving
    }
  }

  /// Add a single voucher to cache
  Future<void> addVoucher(Map<String, dynamic> voucher) async {
    try {
      final vouchers = getVouchers() ?? [];
      // Check if voucher with same username already exists
      final index =
          vouchers.indexWhere((v) => v['username'] == voucher['username']);
      if (index != -1) {
        vouchers[index] = voucher; // Update existing
      } else {
        vouchers.insert(0, voucher); // Add to beginning
      }
      await _cacheBox.put(_vouchersKey, vouchers);
    } catch (e) {
      // Error adding
    }
  }

  /// Add multiple vouchers to cache
  Future<void> addVouchers(List<Map<String, dynamic>> newVouchers) async {
    try {
      final vouchers = getVouchers() ?? [];
      // Add new vouchers to the beginning
      for (final voucher in newVouchers) {
        final index =
            vouchers.indexWhere((v) => v['username'] == voucher['username']);
        if (index != -1) {
          vouchers[index] = voucher; // Update existing
        } else {
          vouchers.insert(0, voucher);
        }
      }
      await _cacheBox.put(_vouchersKey, vouchers);
    } catch (e) {
      // Error adding
    }
  }

  /// Delete a voucher from cache
  Future<void> deleteVoucher(String username) async {
    try {
      final vouchers = getVouchers();
      if (vouchers == null) return;

      vouchers.removeWhere((v) => v['username'] == username);
      await _cacheBox.put(_vouchersKey, vouchers);
    } catch (e) {
      // Error deleting
    }
  }

  /// Update specific fields of a voucher by username
  Future<void> updateVoucher(
      String username, Map<String, dynamic> updates) async {
    try {
      final vouchers = getVouchers();
      if (vouchers == null) return;

      final index = vouchers.indexWhere((v) => v['username'] == username);
      if (index == -1) return;

      vouchers[index] = {...vouchers[index], ...updates};
      await _cacheBox.put(_vouchersKey, vouchers);
    } catch (e) {
      // Error updating
    }
  }

  /// Clear all vouchers from cache
  Future<void> clearVouchers() async {
    await clearEntry(_vouchersKey);
  }

  /// Get app settings (country, currency, company name)
  Map<String, dynamic>? getAppSettings() {
    try {
      final data = _cacheBox.get(_appSettingsKey);
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save app settings
  Future<void> saveAppSettings({
    required String country,
    required String currency,
    String? companyName,
    String? loginUrl,
  }) async {
    try {
      final current = getAppSettings() ?? {};
      await _cacheBox.put(_appSettingsKey, {
        'country': country,
        'currency': currency,
        'companyName': companyName ?? current['companyName'] ?? '',
        'loginUrl': loginUrl ?? current['loginUrl'] ?? 'http://wifi.local',
      });
    } catch (e) {
      // Error saving settings
    }
  }

}
