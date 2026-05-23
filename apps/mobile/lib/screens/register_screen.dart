import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  bool _obscure = true;
  int _step = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _companyCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  void _updateSlug(String name) {
    _slugCtrl.text = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      tenantName: _companyCtrl.text.trim(),
      tenantSlug: _slugCtrl.text.trim(),
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
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _step > 0 ? () => setState(() => _step--) : () => Navigator.pop(context),
        ),
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
                _buildStepIndicator(),
                const SizedBox(height: 24),

                if (_step == 0) _buildAccountStep(),
                if (_step == 1) _buildCompanyStep(),

                if (_step == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _step = 1);
                          }
                        },
                        child: const Text('Next'),
                      ),
                    ),
                  ),

                if (_step == 1) ...[
                  const SizedBox(height: 12),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: AppTheme.danger),
                              const SizedBox(width: 8),
                              Expanded(child: Text(auth.error!, style: const TextStyle(fontSize: 13, color: AppTheme.danger))),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.status == AuthStatus.loading ? null : _onRegister,
                          child: auth.status == AuthStatus.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Create Account'),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepCircle('1', 'Account', _step >= 0),
        Expanded(child: Container(height: 2, color: _step >= 1 ? AppTheme.primary : AppTheme.border)),
        _stepCircle('2', 'Company', _step >= 1),
      ],
    );
  }

  Widget _stepCircle(String number, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number, style: TextStyle(
              fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppTheme.textMuted,
            )),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: active ? AppTheme.primary : AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Create your account to get started', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, size: 20)),
          textCapitalization: TextCapitalization.words,
          validator: (v) => v == null || v.trim().length < 2 ? 'Name is required (min 2 chars)' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) => v == null || v.length < 8 ? 'Password must be at least 8 characters' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
          validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
        ),
      ],
    );
  }

  Widget _buildCompanyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Company Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Set up your workspace', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _companyCtrl,
          decoration: const InputDecoration(labelText: 'Company Name', prefixIcon: Icon(Icons.business_outlined, size: 20)),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => _updateSlug(v),
          validator: (v) => v == null || v.trim().length < 2 ? 'Company name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _slugCtrl,
          decoration: InputDecoration(
            labelText: 'Company URL',
            prefixIcon: const Icon(Icons.link_outlined, size: 20),
            helperText: 'Your company will be at jagafinance.com/${_slugCtrl.text}',
            helperStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Slug is required';
            if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v)) return 'Only lowercase letters, numbers, and hyphens';
            return null;
          },
        ),
      ],
    );
  }
}
