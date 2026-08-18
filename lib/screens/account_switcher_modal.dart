import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_credentials.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import 'login_screen.dart';
import 'paywall_modal.dart';

class AccountSwitcherModal extends StatelessWidget {
  const AccountSwitcherModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountSwitcherModal(),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    UserCredentials creds,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
        title: const Text(
          'アカウントの削除',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${creds.email} の認証情報を端末から削除しますか？',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('削除', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final purchaseProvider = context.read<PurchaseProvider>();
      context.read<AuthProvider>().removeAccount(
        creds.email,
        onAccountChanged: (newEmail) {
          if (newEmail != null) {
            purchaseProvider.identifyUser(newEmail);
          } else {
            purchaseProvider.logout();
          }
        },
      );
    }
  }

  Future<void> _confirmLogoutAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
        title: const Text(
          'すべてのアカウントからログアウト',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '保存されているすべてのアカウント認証情報を削除してログアウトします。よろしいですか？',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ログアウト', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      final purchaseProvider = context.read<PurchaseProvider>();
      context.read<AuthProvider>().logoutAll(
        onLogout: () {
          purchaseProvider.logout();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final purchaseProvider = context.watch<PurchaseProvider>();
    final savedAccounts = authProvider.savedAccounts;
    final activeEmail = authProvider.credentials?.email.toLowerCase() ?? '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF444444),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.manage_accounts, color: Color(0xFFFF434F), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'アカウント切替・管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF888888)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            '保存済みアカウント',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Accounts List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: savedAccounts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final creds = savedAccounts[index];
                final isActive = creds.email.toLowerCase() == activeEmail;

                return InkWell(
                  onTap: isActive
                      ? null
                      : () {
                          authProvider.switchAccount(
                            creds,
                            onUserIdentified: (email) {
                              purchaseProvider.identifyUser(email);
                            },
                          );
                          Navigator.of(context).pop();
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFF434F).withValues(alpha: 0.15)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFFF434F)
                            : const Color(0xFF2C2C2C),
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isActive
                              ? const Color(0xFFFF434F)
                              : const Color(0xFF333333),
                          child: Icon(
                            isActive ? Icons.check : Icons.person_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                creds.email,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      isActive ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isActive ? '選択中のアカウント' : 'タップして切り替え',
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFFFF434F)
                                      : const Color(0xFF777777),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete account button
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFF888888),
                            size: 20,
                          ),
                          tooltip: 'アカウント削除',
                          onPressed: () => _confirmDeleteAccount(context, creds),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Add Account Button
          OutlinedButton.icon(
            onPressed: () {
              if (purchaseProvider.isPro) {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(isAddingAccount: true),
                  ),
                );
              } else {
                Navigator.of(context).pop();
                PaywallModal.show(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('アカウントの追加はPro版限定機能です。'),
                    backgroundColor: Color(0xFFFF434F),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: Icon(
              purchaseProvider.isPro ? Icons.person_add_alt_1 : Icons.lock_outline,
              color: const Color(0xFFFF434F),
            ),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'アカウントを追加',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (!purchaseProvider.isPro) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF434F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFFF434F), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout All Button
          TextButton.icon(
            onPressed: () => _confirmLogoutAll(context),
            icon: const Icon(Icons.logout, color: Color(0xFFFF4B4B), size: 18),
            label: const Text(
              'すべてのアカウントからログアウト',
              style: TextStyle(
                color: Color(0xFFFF4B4B),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
