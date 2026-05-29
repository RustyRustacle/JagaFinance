import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _slugController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _step = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  void _onCompanyChanged(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp('^-+|-+\$'), '');
    _slugController.text = slug;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.register(
      RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        tenantName: _companyController.text.trim(),
        tenantSlug: _slugController.text.trim(),
      ),
    );
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _step == 1 ? () => Navigator.pop(context) : () => setState(() => _step = 1),
        ),
        title: const Text('Daftar Akun Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _stepIndicator(1, 'Akun'),
                    const Expanded(child: Divider(color: AppTheme.border, thickness: 2)),
                    _stepIndicator(2, 'Perusahaan'),
                  ],
                ),
                const SizedBox(height: 32),
                if (_step == 1) ..._buildStep1(),
                if (_step == 2) ..._buildStep2(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator(int step, String label) {
    final isActive = _step >= step;
    final isDone = _step > step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? AppTheme.success : isActive ? AppTheme.primary : AppTheme.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppTheme.textTertiary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppTheme.primary : AppTheme.textTertiary)),
      ],
    );
  }

  List<Widget> _buildStep1() {
    return [
      const Text('Informasi Akun', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 4),
      const Text('Buat akun untuk mulai menggunakan JagaFinance', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Nama Lengkap',
          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
        ),
        validator: (v) => v == null || v.trim().length < 2 ? 'Nama minimal 2 karakter' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined, size: 20),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email harus diisi';
          if (!v.contains('@')) return 'Format email tidak valid';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) => v == null || v.length < 8 ? 'Password minimal 8 karakter' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirm,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Konfirmasi Password',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        validator: (v) => v != _passwordController.text ? 'Password tidak sama' : null,
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              setState(() => _step = 2);
            }
          },
          child: const Text('Lanjutkan'),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildStep2() {
    return [
      const Text('Informasi Perusahaan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 4),
      const Text('Detail perusahaan Anda untuk mulai mengelola pengeluaran', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _companyController,
        textInputAction: TextInputAction.next,
        onChanged: _onCompanyChanged,
        decoration: const InputDecoration(
          labelText: 'Nama Perusahaan',
          prefixIcon: Icon(Icons.business_outlined, size: 20),
        ),
        validator: (v) => v == null || v.trim().length < 2 ? 'Nama perusahaan minimal 2 karakter' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _slugController,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Link Perusahaan',
          prefixIcon: Icon(Icons.link_rounded, size: 20),
          prefixText: 'jagafinance.com/',
          prefixStyle: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
        ),
        validator: (v) {
          if (v == null || v.trim().length < 2) return 'Link perusahaan harus diisi';
          if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v)) return 'Hanya huruf kecil, angka, dan strip';
          return null;
        },
      ),
      const SizedBox(height: 32),
      Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.errorMessage != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppTheme.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.errorMessage!, style: const TextStyle(fontSize: 13, color: AppTheme.danger))),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      SizedBox(
        width: double.infinity,
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return ElevatedButton(
              onPressed: auth.status == AuthStatus.loading ? null : _handleRegister,
              child: auth.status == AuthStatus.loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Daftar Sekarang'),
            );
          },
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}
