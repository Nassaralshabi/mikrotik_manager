/// Reusable filter utilities for consistent filtering across the app
class FilterUtils {
  /// Filter a list of items by search query against multiple fields
  static List<T> filterBySearch<T>(
    List<T> items,
    String searchQuery,
    List<String Function(T)> fieldGetters,
  ) {
    if (searchQuery.isEmpty) return items;

    final query = searchQuery.toLowerCase();
    return items.where((item) {
      return fieldGetters.any((getter) {
        final value = getter(item);
        if (value.isEmpty) return false;
        return value.toLowerCase().contains(query);
      });
    }).toList();
  }

  /// Filter items by date range
  static List<T> filterByDateRange<T>(
    List<T> items,
    DateTime? startDate,
    DateTime? endDate,
    DateTime Function(T) timestampGetter,
  ) {
    var filtered = items;

    if (startDate != null) {
      filtered = filtered.where((item) {
        final timestamp = timestampGetter(item);
        return timestamp.isAfter(startDate) ||
            timestamp.isAtSameMomentAs(startDate);
      }).toList();
    }

    if (endDate != null) {
      final endOfDay =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered = filtered.where((item) {
        final timestamp = timestampGetter(item);
        return timestamp.isBefore(endOfDay) ||
            timestamp.isAtSameMomentAs(endOfDay);
      }).toList();
    }

    return filtered;
  }

  /// Filter items by a specific field value
  static List<T> filterByField<T>(
    List<T> items,
    String? fieldValue,
    String Function(T) fieldGetter,
  ) {
    if (fieldValue == null) return items;
    return items.where((item) => fieldGetter(item) == fieldValue).toList();
  }

  /// Get unique values from a list for filter chips
  static List<String> getUniqueValues<T>(
    List<T> items,
    String Function(T) fieldGetter,
  ) {
    return items.map((item) => fieldGetter(item)).toSet().toList()..sort();
  }

  /// Sort items by date (newest or oldest first)
  static List<T> sortByDate<T>(
    List<T> items,
    DateTime Function(T) timestampGetter, {
    bool newestFirst = true,
  }) {
    final sorted = List<T>.from(items);
    sorted.sort((a, b) {
      final aDate = timestampGetter(a);
      final bDate = timestampGetter(b);
      return newestFirst ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });
    return sorted;
  }

  /// Sort items alphabetically by a string field
  static List<T> sortAlphabetically<T>(
    List<T> items,
    String Function(T) fieldGetter, {
    bool ascending = true,
  }) {
    final sorted = List<T>.from(items);
    sorted.sort((a, b) {
      final aVal = fieldGetter(a).toLowerCase();
      final bVal = fieldGetter(b).toLowerCase();
      return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });
    return sorted;
  }

  /// Format currency for display
  static String formatCurrency(double value, {String symbol = 'Rp '}) {
    if (value >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${value.toStringAsFixed(0)}';
  }

  /// Format relative time (e.g., "5m ago", "2h ago")
  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
