import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

enum _LoginMode { employee, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  _LoginMode _mode = _LoginMode.employee;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final data = _mode == _LoginMode.admin
          ? await ApiService.loginAdmin(username, password)
          : await ApiService.loginEmployee(username, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data['success'] == true) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = data['message']?.toString() ??
              'We could not sign you in. Please check your details.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to connect right now. Please try again.';
      });
    }
  }

  void _showContactAdminDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Need access?'),
          content: const Text(
            'If you do not have a login yet, please contact your HR or system administrator to get an account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  void _openRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _mode == _LoginMode.admin;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroCard(isAdmin),
              const SizedBox(height: 20),
              _buildFormCard(isAdmin),
              const SizedBox(height: 16),
              _buildSupportCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brandDark, AppTheme.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.28),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HRM Doorstep',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance, leave, profile, and updates in one place.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroChip(icon: Icons.qr_code_scanner_rounded, label: 'Scan fast'),
              _HeroChip(icon: Icons.event_note_rounded, label: 'Request leave'),
              _HeroChip(icon: Icons.notifications_rounded, label: 'Stay updated'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isAdmin ? 'Admin access' : 'Employee access',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'Sign in to manage records and approvals.'
                : 'Sign in to check in, request leave, and track your history.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in with your account details.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ToggleButtons(
              isSelected: [_mode == _LoginMode.employee, _mode == _LoginMode.admin],
              onPressed: (index) {
                setState(() {
                  _mode = index == 0 ? _LoginMode.employee : _LoginMode.admin;
                });
              },
              borderRadius: BorderRadius.circular(16),
              borderColor: const Color(0xFFD9E6F8),
              selectedBorderColor: AppTheme.brand,
              selectedColor: Colors.white,
              fillColor: AppTheme.brand,
              color: AppTheme.textSecondary,
              constraints: const BoxConstraints(minHeight: 46),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Employee'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Admin'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppTheme.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'Enter your username',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isLoading) {
                  _login();
                }
              },
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                hintText: 'Enter your password',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isAdmin ? 'Sign in as Admin' : 'Sign in'),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _openRegister,
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.brandSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E8FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppTheme.brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Need help getting in?',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Contact your administrator if you need an account or have trouble signing in.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _showContactAdminDialog,
            child: const Text('Contact administrator'),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
