import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mail_provider.dart';
import '../providers/purchase_provider.dart';
import 'account_switcher_modal.dart';
import 'paywall_modal.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Future<void> _handleBulkRead(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final mailProvider = context.read<MailProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();

    final credentials = authProvider.credentials;
    if (credentials == null) return;

    // Verify Pro entitlement status with RevenueCat server before executing bulk read
    await purchaseProvider.checkProStatus();

    final result = await mailProvider.executeBulkRead(
      credentials: credentials,
      isPro: purchaseProvider.isPro,
    );

    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.count > 0
                      ? '${result.count} 件の未読メールを既読にしました'
                      : '未読メールはありませんでした',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'エラーが発生しました'),
          backgroundColor: const Color(0xFFFF434F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mailProvider = context.watch<MailProvider>();
    final purchaseProvider = context.watch<PurchaseProvider>();

    final credentials = authProvider.credentials;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure Black Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '一括既読プロ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          // Account Switcher Action Button (Top Right Red Icon)
          IconButton(
            icon: const Icon(
              Icons.manage_accounts,
              color: Color(0xFFFF4B4B),
              size: 26,
            ),
            tooltip: 'アカウント切替・管理',
            onPressed: mailProvider.isProcessing
                ? null
                : () => AccountSwitcherModal.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Active User Info Chip (Tap to open Account Switcher)
            if (credentials != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: mailProvider.isProcessing
                    ? null
                    : () => AccountSwitcherModal.show(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_circle, color: Color(0xFFFF434F), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        credentials.maskedEmail,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF888888),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Central Area with 240px Circular Glow Button
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: mailProvider.isProcessing
                            ? null
                            : () => _handleBulkRead(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF434F),
                                Color(0xFFFF5252),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF434F).withValues(
                                  alpha: mailProvider.isProcessing ? 0.2 : 0.5,
                                ),
                                blurRadius: mailProvider.isProcessing ? 15 : 40,
                                spreadRadius: mailProvider.isProcessing ? 2 : 8,
                              ),
                            ],
                          ),
                          child: mailProvider.isProcessing
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 4.0,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      '既読化処理中...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // White Circle with Red Checkmark Icon
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 48,
                                        color: Color(0xFFFF434F),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Bold white action text
                                    const Text(
                                      'すべて既読にする',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Status / Footer Section
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: GestureDetector(
                onTap: purchaseProvider.isPro
                    ? null
                    : () => PaywallModal.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: purchaseProvider.isPro
                          ? const Color(0xFF262626)
                          : const Color(0xFFFF434F).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        purchaseProvider.isPro
                            ? Icons.verified_user
                            : Icons.workspace_premium,
                        color: purchaseProvider.isPro
                            ? Colors.greenAccent
                            : const Color(0xFFFF434F),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          purchaseProvider.isPro
                              ? '有料版：一回ですべての未読を処理します'
                              : '無料版：1回で最新50件まで既読（タップしてProにアップグレード）',
                          style: TextStyle(
                            color: purchaseProvider.isPro
                                ? const Color(0xFF888888)
                                : const Color(0xFFCCCCCC),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (!purchaseProvider.isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF434F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'アップグレード',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
