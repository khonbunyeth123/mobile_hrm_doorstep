import 'package:flutter/material.dart';
import '../screens/notification_screen.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> _profile = {};
  int _unreadNotifications = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final profile = await ProfileService.getCachedProfile();
    final unread = await NotificationStorage.unreadCount();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _unreadNotifications = unread;
      _loading = false;
    });
  }

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String _todayLabel() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _prettyRole(String role) {
    final cleaned = role.trim().replaceAll('_', ' ');
    if (cleaned.isEmpty) return 'Employee';
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile['full_name'] ?? '';
    final firstName = _firstName(name);
    final role = (_profile['role'] ?? '').trim().isNotEmpty
        ? _profile['role']!
        : 'Employee';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        _unreadNotifications > 99
                            ? '99+'
                            : '$_unreadNotifications',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(firstName, role),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.notifications_rounded,
                            title: 'Unread',
                            value: '$_unreadNotifications',
                            accent: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.today_rounded,
                            title: 'Today',
                            value: DateTime.now().day.toString(),
                            accent: AppTheme.brand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.verified_user_rounded,
                            title: 'Role',
                            value: _prettyRole(role),
                            accent: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Quick actions',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Scan QR',
                          subtitle: 'Check in or check out',
                          accent: AppTheme.brand,
                          onTap: () => Navigator.pushNamed(context, '/menu-scan'),
                        ),
                        _buildActionCard(
                          icon: Icons.event_note_rounded,
                          title: 'Leave request',
                          subtitle: 'Submit time off',
                          accent: AppTheme.accent,
                          onTap: () =>
                              Navigator.pushNamed(context, '/leave-request'),
                        ),
                        _buildActionCard(
                          icon: Icons.history_rounded,
                          title: 'History',
                          subtitle: 'Review activity',
                          accent: const Color(0xFF7C3AED),
                          onTap: () => Navigator.pushNamed(context, '/history'),
                        ),
                        _buildActionCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'Calendar',
                          subtitle: 'View schedule',
                          accent: AppTheme.brand,
                          onTap: () => Navigator.pushNamed(context, '/calendar'),
                        ),
                        _buildActionCard(
                          icon: Icons.person_rounded,
                          title: 'Profile',
                          subtitle: 'Update details',
                          accent: const Color(0xFFEA580C),
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildInfoCard(
                      icon: Icons.tips_and_updates_rounded,
                      title: 'Tip of the day',
                      body:
                          'Use the scanner for attendance, then check notifications for approval updates and leave status.',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.support_agent_rounded,
                      title: 'Need help?',
                      body:
                          'Open your profile for account details or use notifications to keep track of updates.',
                      actionLabel: 'View notifications',
                      onAction: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard(String firstName, String role) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brandDark, AppTheme.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.isNotEmpty ? role : 'Employee',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Everything you need for attendance, leave, and account updates in one simple place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(Icons.access_time_rounded, _todayLabel()),
              _pill(
                Icons.notifications_rounded,
                _unreadNotifications == 0
                    ? 'No unread notifications'
                    : '$_unreadNotifications unread',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7EEF8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.brand, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}
