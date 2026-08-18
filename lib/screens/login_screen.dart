import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';

class LoginScreen extends StatefulWidget {
  final bool isAddingAccount;

  const LoginScreen({
    super.key,
    this.isAddingAccount = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const String _appPasswordHelpUrl =
      'https://myaccount.google.com/apppasswords';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openHelpUrl() async {
    final uri = Uri.parse(_appPasswordHelpUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ブラウザを開くことができませんでした。'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();

    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
      onUserIdentified: (email) {
        purchaseProvider.identifyUser(email);
      },
    );

    if (!mounted) return;

    if (success) {
      if (widget.isAddingAccount) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('新しいアカウントを追加しました'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: const Color(0xFFFF434F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure Black Background
      appBar: widget.isAddingAccount
          ? AppBar(
              backgroundColor: const Color(0xFF000000),
              elevation: 0,
              title: const Text(
                'アカウントの追加',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF434F),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF434F).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_email_read,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header Title
                  Text(
                    widget.isAddingAccount ? '新しいGmailを追加' : '一括既読プロ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gmailアカウント情報を入力してログイン',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Gmail Address Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Gmailアドレス',
                      labelStyle: const TextStyle(color: Color(0xFF888888)),
                      hintText: 'example@gmail.com',
                      hintStyle: const TextStyle(color: Color(0xFF444444)),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF434F)),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF222222)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFF434F), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Gmailアドレスを入力してください';
                      }
                      if (!value.contains('@')) {
                        return '有効なメールアドレス形式で入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // App Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'アプリパスワード（16桁）',
                      labelStyle: const TextStyle(color: Color(0xFF888888)),
                      hintText: 'xxxx xxxx xxxx xxxx',
                      hintStyle: const TextStyle(color: Color(0xFF444444)),
                      prefixIcon: const Icon(Icons.key_outlined, color: Color(0xFFFF434F)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF888888),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF222222)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFF434F), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'アプリパスワードを入力してください';
                      }
                      final sanitized = value.replaceAll(' ', '');
                      if (sanitized.length < 16) {
                        return '16桁のアプリパスワードを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Help Link: Googleアプリパスワードの取得方法
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openHelpUrl,
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Color(0xFFFF434F),
                      ),
                      label: const Text(
                        'Googleアプリパスワードの取得方法',
                        style: TextStyle(
                          color: Color(0xFFFF434F),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFFF434F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF434F),
                        disabledBackgroundColor: const Color(0xFF552226),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFFFF434F).withValues(alpha: 0.5),
                      ),
                      child: authProvider.isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'IMAP接続確認中...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              widget.isAddingAccount ? 'アカウントを追加' : 'ログインして始める',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Security Notice Note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF222222)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF888888),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '認証情報は端末の安全な暗号化領域（Keychain / Keystore）に保存され、外部サーバーに送信されることはありません。',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
