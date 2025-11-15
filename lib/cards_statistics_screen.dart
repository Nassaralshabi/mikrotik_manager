import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'theme/app_theme.dart';
import 'mikrotik_connector.dart';

enum TimeRange { all, today, week, month, custom }

enum CardStatusFilter { all, active, disabled, expired, withSessions }

class CardsStatisticsScreen extends StatefulWidget {
  const CardsStatisticsScreen({super.key});

  @override
  State<CardsStatisticsScreen> createState() => _CardsStatisticsScreenState();
}

class _CardsStatisticsScreenState extends State<CardsStatisticsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;

  int _totalCards = 0;
  int _activeCards = 0;
  int _disabledCards = 0;
  int _expiredCards = 0;
  int _cardsWithSessions = 0;
  int _totalSessions = 0;

  double _totalUploadGB = 0.0;
  double _totalDownloadGB = 0.0;
  Map<String, int> _cardsByProfile = {};

  TimeRange _selectedRange = TimeRange.all;
  CardStatusFilter _statusFilter = CardStatusFilter.all;
  String? _selectedProfile;
  
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  List<Map<String, dynamic>> _usersRaw = [];
  List<Map<String, dynamic>> _sessionsRaw = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  
  // Cache للبيانات لتحسين الأداء
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 2);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatistics() async {
    // التحقق من الـ cache
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _usersRaw.isNotEmpty) {
      _applyFilters();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final usersResponse = await client.talk([
        '/tool/user-manager/user/print',
      ]).timeout(const Duration(seconds: 10));

      final sessionsResponse = await client.talk([
        '/tool/user-manager/session/print',
      ]).timeout(const Duration(seconds: 10));

      _usersRaw = usersResponse.map((e) => Map<String, dynamic>.from(e)).toList();
      _sessionsRaw = sessionsResponse.map((e) => Map<String, dynamic>.from(e)).toList();
      _lastFetchTime = DateTime.now(); // حفظ وقت آخر fetch

      _applyFilters();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل تحميل الإحصائيات: ${e.toString()}';
        });
      }
    } finally {
      client?.close();
    }
  }

  void _applyFilters() {
    // Filter by date range
    DateTime? startDate;
    DateTime? endDate = DateTime.now();
    
    switch (_selectedRange) {
      case TimeRange.today:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case TimeRange.week:
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startDate = endDate.subtract(const Duration(days: 30));
        break;
      case TimeRange.custom:
        startDate = _customStartDate;
        endDate = _customEndDate ?? DateTime.now();
        break;
      case TimeRange.all:
        startDate = null;
        break;
    }

    _filteredUsers = List.from(_usersRaw);

    // Filter by status
    if (_statusFilter != CardStatusFilter.all) {
      final Set<String> usersWithSessions = _sessionsRaw.map((s) => s['user'] as String?).whereType<String>().toSet();
      
      _filteredUsers = _filteredUsers.where((user) {
        switch (_statusFilter) {
          case CardStatusFilter.active:
            return user['disabled'] != 'true';
          case CardStatusFilter.disabled:
            return user['disabled'] == 'true';
          case CardStatusFilter.expired:
            return _isCardExpired(user);
          case CardStatusFilter.withSessions:
            return usersWithSessions.contains(user['username']);
          case CardStatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Filter by profile
    if (_selectedProfile != null && _selectedProfile!.isNotEmpty) {
      _filteredUsers = _filteredUsers.where((user) {
        return user['actual-profile'] == _selectedProfile;
      }).toList();
    }

    _calculateStatistics(startDate, endDate);
  }

  bool _isCardExpired(Map<String, dynamic> user) {
    final uptimeLimit = user['uptime-limit'];
    final uptimeUsed = user['uptime-used'];
    
    if (uptimeLimit == null || uptimeUsed == null) return false;
    
    try {
      final limitDuration = _parseRosDuration(uptimeLimit.toString());
      final usedDuration = _parseRosDuration(uptimeUsed.toString());
      
      return usedDuration.inSeconds >= limitDuration.inSeconds && limitDuration.inSeconds > 0;
    } catch (e) {
      return false;
    }
  }

  void _calculateStatistics(DateTime? startDate, DateTime? endDate) {
    _totalCards = _filteredUsers.length;
    _activeCards = 0;
    _disabledCards = 0;
    _expiredCards = 0;
    _cardsByProfile.clear();

    double allTimeUploadBytes = 0.0;
    double allTimeDownloadBytes = 0.0;

    for (final user in _filteredUsers) {
      final disabled = user['disabled'] == 'true';
      if (disabled) {
        _disabledCards++;
      } else {
        _activeCards++;
      }
      
      if (_isCardExpired(user)) {
        _expiredCards++;
      }

      final uploadUsed = double.tryParse(user['upload-used'] ?? '0') ?? 0.0;
      final downloadUsed = double.tryParse(user['download-used'] ?? '0') ?? 0.0;
      allTimeUploadBytes += uploadUsed;
      allTimeDownloadBytes += downloadUsed;

      final profile = user['actual-profile'] ?? 'غير محدد';
      _cardsByProfile[profile] = (_cardsByProfile[profile] ?? 0) + 1;
    }

    // Filter sessions by date and users
    List<Map<String, dynamic>> filteredSessions = _sessionsRaw;
    
    if (startDate != null) {
      filteredSessions = filteredSessions.where((s) {
        final DateTime? st = _inferSessionStartTime(s);
        if (st == null) return false;
        return st.isAfter(startDate) && st.isBefore(endDate!);
      }).toList();
    }
    
    // Filter sessions by filtered users
    final filteredUsernames = _filteredUsers.map((u) => u['username'] as String?).whereType<String>().toSet();
    filteredSessions = filteredSessions.where((s) => filteredUsernames.contains(s['user'])).toList();

    final Set<String> usersWithSessions = {};
    double periodUploadBytes = 0.0;
    double periodDownloadBytes = 0.0;

    for (final s in filteredSessions) {
      final u = s['user'];
      if (u != null) usersWithSessions.add(u);
      final su = double.tryParse(s['upload'] ?? '0') ?? 0.0;
      final sd = double.tryParse(s['download'] ?? '0') ?? 0.0;
      periodUploadBytes += su;
      periodDownloadBytes += sd;
    }

    _cardsWithSessions = usersWithSessions.length;
    _totalSessions = filteredSessions.length;

    if (_selectedRange == TimeRange.all || startDate == null) {
      _totalUploadGB = allTimeUploadBytes / (1024 * 1024 * 1024);
      _totalDownloadGB = allTimeDownloadBytes / (1024 * 1024 * 1024);
    } else {
      _totalUploadGB = periodUploadBytes / (1024 * 1024 * 1024);
      _totalDownloadGB = periodDownloadBytes / (1024 * 1024 * 1024);
    }
  }

  DateTime? _inferSessionStartTime(Map<String, dynamic> session) {
    final uptimeStr = session['uptime'];
    if (uptimeStr is String && uptimeStr.isNotEmpty) {
      final d = _parseRosDuration(uptimeStr);
      return DateTime.now().subtract(d);
    }
    final st = session['start-time'];
    if (st is String && st.isNotEmpty) {
      try {
        return DateTime.parse(st);
      } catch (_) {}
    }
    return null;
  }

  Duration _parseRosDuration(String s) {
    int weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0;
    String num = '';
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (RegExp(r'\d').hasMatch(ch)) {
        num += ch;
      } else {
        final v = int.tryParse(num) ?? 0;
        switch (ch) {
          case 'w':
            weeks = v;
            break;
          case 'd':
            days = v;
            break;
          case 'h':
            hours = v;
            break;
          case 'm':
            minutes = v;
            break;
          case 's':
            seconds = v;
            break;
        }
        num = '';
      }
    }
    return Duration(days: (weeks * 7) + days, hours: hours, minutes: minutes, seconds: seconds);
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedRange = TimeRange.custom;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إحصائيات الكروت', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'الفلاتر',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStatistics,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل الإحصائيات...',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: context.theme.appColors.error.withOpacity(0.8)),
                        const SizedBox(height: 24),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87, fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          onPressed: _fetchStatistics,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _fetchStatistics,
                    color: theme.primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showFilters) ...[
                            _buildFiltersSection(theme),
                            const SizedBox(height: 20),
                          ],
                          _buildActiveFiltersChips(theme),
                          const SizedBox(height: 16),
                          _buildRangeSelector(theme),
                          const SizedBox(height: 20),
                          _buildMainStatCard(theme),
                          const SizedBox(height: 16),
                          _buildStatusCardsGrid(theme),
                          const SizedBox(height: 16),
                          _buildDataUsageCard(theme),
                          const SizedBox(height: 16),
                          _buildProfilesCard(theme),
                          const SizedBox(height: 16),
                          _buildQuickStatsGrid(theme),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    final allProfiles = _usersRaw.map((u) => u['actual-profile'] as String? ?? 'غير محدد').toSet().toList()..sort();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: theme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'فلترة متقدمة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Status Filter
          Text('حالة الكرت', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CardStatusFilter.values.map((filter) {
              final selected = _statusFilter == filter;
              String label;
              IconData icon;
              
              switch (filter) {
                case CardStatusFilter.all:
                  label = 'الكل';
                  icon = Icons.select_all;
                  break;
                case CardStatusFilter.active:
                  label = 'مفعل';
                  icon = Icons.check_circle;
                  break;
                case CardStatusFilter.disabled:
                  label = 'معطل';
                  icon = Icons.cancel;
                  break;
                case CardStatusFilter.expired:
                  label = 'منتهي';
                  icon = Icons.hourglass_empty;
                  break;
                case CardStatusFilter.withSessions:
                  label = 'نشط الآن';
                  icon = Icons.wifi;
                  break;
              }
              
              return FilterChip(
                selected: selected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: selected ? Colors.white : Colors.white60),
                    const SizedBox(width: 6),
                    Text(label),
                  ],
                ),
                onSelected: (value) {
                  setState(() {
                    _statusFilter = filter;
                    _applyFilters();
                  });
                },
                backgroundColor: theme.cardColor,
                selectedColor: theme.primaryColor,
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87),
                side: BorderSide(color: selected ? theme.primaryColor : Colors.white30),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Profile Filter
          Text('الفئة', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedProfile,
                hint: Text('اختر الفئة', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54)),
                dropdownColor: theme.cardColor,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('جميع الفئات', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87)),
                  ),
                  ...allProfiles.map((profile) {
                    return DropdownMenuItem<String>(
                      value: profile,
                      child: Text(profile, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProfile = value;
                    _applyFilters();
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Reset Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة تعيين الفلاتر'),
              onPressed: () {
                setState(() {
                  _statusFilter = CardStatusFilter.all;
                  _selectedProfile = null;
                  _selectedRange = TimeRange.all;
                  _customStartDate = null;
                  _customEndDate = null;
                  _applyFilters();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(ThemeData theme) {
    List<Widget> chips = [];
    
    if (_statusFilter != CardStatusFilter.all) {
      String label;
      switch (_statusFilter) {
        case CardStatusFilter.active:
          label = 'مفعل';
          break;
        case CardStatusFilter.disabled:
          label = 'معطل';
          break;
        case CardStatusFilter.expired:
          label = 'منتهي';
          break;
        case CardStatusFilter.withSessions:
          label = 'نشط الآن';
          break;
        default:
          label = '';
      }
      
      chips.add(
        Chip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _statusFilter = CardStatusFilter.all;
              _applyFilters();
            });
          },
          backgroundColor: theme.primaryColor.withOpacity(0.2),
          side: BorderSide(color: theme.primaryColor),
        ),
      );
    }
    
    if (_selectedProfile != null) {
      chips.add(
        Chip(
          label: Text(_selectedProfile!, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _selectedProfile = null;
              _applyFilters();
            });
          },
          backgroundColor: theme.primaryColor.withOpacity(0.2),
          side: BorderSide(color: theme.primaryColor),
        ),
      );
    }
    
    if (_selectedRange == TimeRange.custom && _customStartDate != null && _customEndDate != null) {
      chips.add(
        Chip(
          label: Text(
            '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}',
            style: const TextStyle(fontSize: 12),
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _selectedRange = TimeRange.all;
              _customStartDate = null;
              _customEndDate = null;
              _applyFilters();
            });
          },
          backgroundColor: theme.primaryColor.withOpacity(0.2),
          side: BorderSide(color: theme.primaryColor),
        ),
      );
    }
    
    if (chips.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الفلاتر النشطة:', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildRangeSelector(ThemeData theme) {
    String label(TimeRange r) {
      switch (r) {
        case TimeRange.today:
          return 'اليوم';
        case TimeRange.week:
          return 'أسبوع';
        case TimeRange.month:
          return 'شهر';
        case TimeRange.custom:
          return 'مخصص';
        case TimeRange.all:
          return 'الكل';
      }
    }

    final items = TimeRange.values;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: items.map((r) {
          final selected = _selectedRange == r;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (r == TimeRange.custom) {
                  _pickDateRange();
                } else {
                  setState(() {
                    _selectedRange = r;
                    _customStartDate = null;
                    _customEndDate = null;
                    _applyFilters();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (r == TimeRange.custom)
                      Icon(
                        Icons.date_range,
                        size: 16,
                        color: selected ? Colors.white : Colors.white60,
                      ),
                    if (r == TimeRange.custom) const SizedBox(height: 4),
                    Text(
                      label(r),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainStatCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.8),
            theme.primaryColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.credit_card, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            '$_totalCards',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'إجمالي الكروت',
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('مفعل', _activeCards, Icons.check_circle, context.theme.appColors.success),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildMiniStat('معطل', _disabledCards, Icons.cancel, context.theme.appColors.error),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildMiniStat('منتهي', _expiredCards, Icons.hourglass_empty, context.theme.appColors.warning),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildMiniStat('نشط', _cardsWithSessions, Icons.wifi, context.theme.appColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCardsGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildSmallStatCard(
          'الجلسات النشطة',
          _totalSessions,
          Icons.devices,
          context.theme.appColors.warning,
          theme,
        ),
        _buildSmallStatCard(
          'معدل النشاط',
          _totalCards > 0 ? ((_cardsWithSessions / _totalCards) * 100).round() : 0,
          Icons.trending_up,
          context.theme.appColors.primary,
          theme,
          suffix: '%',
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String title, int value, IconData icon, Color color, ThemeData theme, {String suffix = ''}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataUsageCard(ThemeData theme) {
    String suffix;
    switch (_selectedRange) {
      case TimeRange.today:
        suffix = ' (اليوم)';
        break;
      case TimeRange.week:
        suffix = ' (آخر 7 أيام)';
        break;
      case TimeRange.month:
        suffix = ' (آخر 30 يوم)';
        break;
      case TimeRange.custom:
        if (_customStartDate != null && _customEndDate != null) {
          suffix = ' (${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)})';
        } else {
          suffix = '';
        }
        break;
      case TimeRange.all:
        suffix = '';
        break;
    }

    final totalData = _totalDownloadGB + _totalUploadGB;
    final downloadPercent = totalData > 0 ? (_totalDownloadGB / totalData) : 0.5;
    final uploadPercent = totalData > 0 ? (_totalUploadGB / totalData) : 0.5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.data_usage, color: theme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'استهلاك البيانات$suffix',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color ?? Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDataColumn(
                  'التحميل',
                  _totalDownloadGB,
                  Icons.download,
                  context.theme.appColors.success,
                  downloadPercent,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDataColumn(
                  'الرفع',
                  _totalUploadGB,
                  Icons.upload,
                  context.theme.appColors.info,
                  uploadPercent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage, color: context.theme.appColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text('المجموع الكلي', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54)),
                  ],
                ),
                Text(
                  '${totalData.toStringAsFixed(2)} GB',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.theme.appColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataColumn(String label, double value, IconData icon, Color color, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${value.toStringAsFixed(2)} GB',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white.withOpacity(0.1),
            color: color,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(percent * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildProfilesCard(ThemeData theme) {
    if (_cardsByProfile.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedProfiles = _cardsByProfile.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.theme.appColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.category, color: context.theme.appColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'توزيع الكروت حسب الفئة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...sortedProfiles.asMap().entries.map((entry) {
            final index = entry.key;
            final profileEntry = entry.value;
            final percentage = (_totalCards > 0 ? (profileEntry.value / _totalCards) : 0.0);
            
            final colors = [
              context.theme.appColors.primary,
              context.theme.appColors.info,
              context.theme.appColors.success,
              context.theme.appColors.warning,
              Colors.pinkAccent,
              Colors.cyanAccent,
            ];
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          profileEntry.key,
                          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${profileEntry.value} (${(percentage * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(ThemeData theme) {
    final avgSessionsPerCard = _cardsWithSessions > 0 ? (_totalSessions / _cardsWithSessions).toStringAsFixed(1) : '0';
    final activePercentage = _totalCards > 0 ? ((_activeCards / _totalCards) * 100).round() : 0;
    final expiredPercentage = _totalCards > 0 ? ((_expiredCards / _totalCards) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'إحصائيات سريعة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'متوسط الجلسات',
                avgSessionsPerCard,
                Icons.analytics,
                Colors.tealAccent,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                'نسبة التفعيل',
                '$activePercentage%',
                Icons.check_circle_outline,
                Colors.indigoAccent,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'نسبة المنتهي',
                '$expiredPercentage%',
                Icons.hourglass_bottom,
                Colors.deepOrangeAccent,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                'الفئات',
                '${_cardsByProfile.length}',
                Icons.category_outlined,
                Colors.amberAccent,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
