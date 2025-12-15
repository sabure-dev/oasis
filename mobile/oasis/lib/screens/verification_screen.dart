import 'package:flutter/material.dart';
import 'package:oasis/providers/auth_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/services/api_service.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final auth = Provider.of<AuthProvider>(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.startColor, theme.endColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Check your email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a verification code to\n${auth.currentUser?.email ?? "your email"}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),

                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 5),
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "000000",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: theme.startColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Кнопка "Отправить снова"
                TextButton(
                  onPressed: _isLoading ? null : _resendCode,
                  child: const Text('Resend Code', style: TextStyle(color: Colors.white70)),
                ),

                const SizedBox(height: 10),

                // Кнопка "Выйти" (если ошиблись аккаунтом)
                TextButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout, size: 16, color: Colors.white54),
                  label: const Text('Logout', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.confirmVerification(_codeController.text);
      if (mounted) {
        // Обновляем состояние пользователя, чтобы main.dart переключил экран
        await Provider.of<AuthProvider>(context, listen: false).checkAuth();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await _apiService.requestVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code resent! Check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}