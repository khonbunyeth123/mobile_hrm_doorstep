import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

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
  String? _photoUrl; // ✅ photo URL

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

    // ✅ Build full photo URL from relative path
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
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
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
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _errorMessage == null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditing) {
                        if (_formKey.currentState!.validate()) _saveProfile();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
            ),
          IconButton(
            onPressed: _isLoggingOut ? null : _showLogoutDialog,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _errorMessage != null
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    // ✅ Show photo if available, otherwise show icon
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : null,
                      onBackgroundImageError: _photoUrl != null
                          ? (_, __) {}
                          : null,
                      child: _photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.blue,
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Photo update coming soon!'),
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _nameController.text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emailController.text,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter your email'
                        : (!v.contains('@') ? 'Invalid email' : null),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    maxLines: 3,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter your address'
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (_formKey.currentState!.validate())
                              _saveProfile();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(     
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextField({
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
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[50],
        labelStyle: TextStyle(
          color: _isEditing ? Colors.grey[700] : Colors.grey[500],
        ),
      ),
      style: TextStyle(color: _isEditing ? Colors.grey[800] : Colors.grey[600]),
    );
  }
}
