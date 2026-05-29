import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  String? _photoUrl;
  String _role = 'Employee';

  Map<String, String> _snapshot = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ProfileService.getProfile();
      _applyData(data);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyData(Map<String, dynamic> data) {
    _nameController.text = data['full_name']?.toString() ?? '';
    _emailController.text = data['email']?.toString() ?? '';
    _phoneController.text =
        data['phone']?.toString() ?? data['phone_number']?.toString() ?? '';
    _addressController.text = data['address']?.toString() ?? '';
    _role = data['role']?.toString().trim().isNotEmpty == true
        ? data['role'].toString()
        : 'Employee';

    final photo = data['photo']?.toString() ?? '';
    if (photo.isNotEmpty) {
      final base = AppConfig.baseUrl.replaceAll('/api', '');
      _photoUrl = '$base/$photo';
    } else {
      _photoUrl = null;
    }

    _snapshot = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
    };
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ProfileService.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      _snapshot = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      };

      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _nameController.text = _snapshot['name'] ?? '';
      _emailController.text = _snapshot['email'] ?? '';
      _phoneController.text = _snapshot['phone'] ?? '';
      _addressController.text = _snapshot['address'] ?? '';
    });
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Widget _buildHero() {
    final name = _nameController.text.trim().isEmpty
        ? 'Your profile'
        : _nameController.text.trim();
    final email = _emailController.text.trim();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.brandSoft,
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                child: _photoUrl == null
                    ? const Icon(Icons.person_rounded, size: 58, color: AppTheme.brand)
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? 'Keep your details up to date' : email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          AppStatusPill(
            label: _role,
            color: AppTheme.brandDark,
            backgroundColor: AppTheme.brandSoft,
            icon: Icons.badge_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildFormCard() {
    return AppSurfaceCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Personal details',
              subtitle: 'Edit only what changed to keep the update fast.',
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _nameController,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _emailController,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter your address' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelEdit,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppPrimaryButton(
              label: 'Save changes',
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _saveProfile();
                      }
                    },
              loading: _isSaving,
              icon: Icons.save_rounded,
            ),
          ),
        ],
      );
    }

    return AppPrimaryButton(
      label: 'Edit profile',
      onPressed: () => setState(() => _isEditing = true),
      icon: Icons.edit_rounded,
    );
  }

  Widget _buildSupportCard() {
    return AppSurfaceCard(
      color: AppTheme.backgroundAlt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.support_agent_rounded, color: AppTheme.brand),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'If your profile details look wrong, update them here first and then contact HR if the change needs approval on the server side.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal information'),
        actions: [
          if (!_isLoading && _errorMessage == null)
            IconButton(
              tooltip: 'Logout',
              onPressed: _isLoggingOut ? null : _showLogoutDialog,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load profile',
                      message: _errorMessage!,
                      actionLabel: 'Retry',
                      onAction: _loadProfile,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildHero(),
                      const SizedBox(height: 16),
                      _buildFormCard(),
                      const SizedBox(height: 16),
                      _buildActionArea(),
                      const SizedBox(height: 16),
                      _buildSupportCard(),
                    ],
                  ),
                ),
    );
  }
}
