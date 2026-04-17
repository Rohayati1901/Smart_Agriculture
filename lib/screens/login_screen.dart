import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'device_selecetion_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String error = '';

  String? _validateCredentials(String email, String password) {
    if (email.isEmpty) return 'Email wajib diisi.';
    if (password.isEmpty) return 'Password wajib diisi.';
    return null;
  }

  String _authExceptionMessage(
    FirebaseAuthException exception, {
    required String fallback,
  }) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'User tidak ditemukan. Cek lagi email yang dimasukkan.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'invalid-credential':
        return 'Email atau password tidak cocok.';
      case 'user-disabled':
        return 'Akun ini sudah dinonaktifkan.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi gagal. Cek internet lalu coba lagi.';
      default:
        return exception.message ?? fallback;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => error = message);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final validationError = _validateCredentials(email, password);

    if (validationError != null) {
      setState(() => error = validationError);
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      await AuthService.login(email, password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DeviceSelectionScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_authExceptionMessage(e, fallback: 'Login gagal'));
    } catch (_) {
      _showError('Login gagal. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final validationError = _validateCredentials(email, password);

    if (validationError != null) {
      setState(() => error = validationError);
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      await AuthService.register(email, password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DeviceSelectionScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_authExceptionMessage(e, fallback: 'Registrasi gagal'));
    } catch (_) {
      _showError('Registrasi gagal. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFCDECCF),
              Color(0xFFEAF7E4),
              Color(0xFFF7F4EA),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 52,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Smart Agriculture',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F4D1C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Solusi cerdas untuk tanaman sehat tanpa ribet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF45633F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Masuk ke akun',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Gunakan email yang sudah didaftarkan.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5E6E5A),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              obscureText: obscurePassword,
                            ),
                            const SizedBox(height: 16),
                            if (error.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  error,
                                  style: const TextStyle(color: Color(0xFFB3261E)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (error.isNotEmpty) const SizedBox(height: 16),
                            if (isLoading)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              ElevatedButton(
                                onPressed: login,
                                child: const Text('Login'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: register,
                                child: const Text('Buat Akun Baru'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
