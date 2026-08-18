import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';

class PaywallModal extends StatelessWidget {
  const PaywallModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();

    return Container(
      padding: const EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 36,
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
          const SizedBox(height: 20),

          // Crown / Pro Header Icon
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF434F).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFFFF434F), width: 1.5),
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 36,
                color: Color(0xFFFF434F),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Subtitle
          const Text(
            '有料版 (Pro) にアップグレード',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '制限なしですべての未読メールを1タップで一括処理',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 28),

          // Feature list
          _buildFeatureRow(
            icon: Icons.all_inclusive,
            title: '全件一括既読機能',
            subtitle: '50件の制限を解除し、未読メールを全件一度に既読化します。',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            icon: Icons.bolt,
            title: '高速なIMAP通信処理',
            subtitle: 'Gmail APIの制限に縛られず、スムーズに一括処理を実行。',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            icon: Icons.security,
            title: '安心のプライバシー保護',
            subtitle: 'サーバー経由なし。データは全てあなたの端末で処理されます。',
          ),
          const SizedBox(height: 32),

          // Error Message Display
          if (purchaseProvider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                purchaseProvider.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Buy Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: purchaseProvider.isLoading
                  ? null
                  : () async {
                      final success = await purchaseProvider.buyPro();
                      if (context.mounted && success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pro版へのアップグレードが完了しました！'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF434F),
                disabledBackgroundColor: const Color(0xFF552226),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: purchaseProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Pro版を購入する',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Restore Purchases Button
          TextButton(
            onPressed: purchaseProvider.isLoading
                ? null
                : () async {
                    final restored = await purchaseProvider.restorePurchases();
                    if (context.mounted) {
                      if (restored) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('以前の購入が正常に復元されました！'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
            child: const Text(
              '購入内容を復元する (Restore)',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF434F), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
