import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 32, color: AppTheme.primary),
                ),
                const SizedBox(height: 24),
                const Text('JagaFinance', style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                const Text('From scanned receipts to financial\nreports in seconds.', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppTheme.textSecondary, height: 1.4)),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                  children: [
                    _chip(Icons.timer_outlined, '90% Time saved'),
                    _chip(Icons.document_scanner_outlined, 'OCR Auto extract'),
                    _chip(Icons.admin_panel_settings_outlined, 'RBAC Multi-user'),
                  ],
                ),
                const SizedBox(height: 36),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                  validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
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
                  validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
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
                        onPressed: auth.status == AuthStatus.loading ? null : _onSignIn,
                        child: auth.status == AuthStatus.loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: const Color(0xFF94A3B8))),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Sign up", style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
