import 'package:enough_mail/enough_mail.dart';

class MailResult {
  final bool success;
  final int count;
  final String? errorMessage;

  MailResult({
    required this.success,
    this.count = 0,
    this.errorMessage,
  });
}

class MailService {
  static const String _imapHost = 'imap.gmail.com';
  static const int _imapPort = 993;

  /// Tests IMAP connection and credentials with imap.gmail.com:993
  Future<bool> testConnection(String email, String appPassword) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(
        _imapHost,
        _imapPort,
        isSecure: true,
      );
      await client.login(email, appPassword);
      await client.logout();
      return true;
    } catch (e) {
      return false;
    } finally {
      if (client.isConnected) {
        await client.disconnect();
      }
    }
  }

  /// Bulk marks unseen emails as read (\Seen)
  /// If [isPro] is false (Free tier), limits processing to maximum 50 messages.
  Future<MailResult> markAllAsRead({
    required String email,
    required String appPassword,
    required bool isPro,
  }) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      // 1. Connect & Authenticate
      await client.connectToServer(
        _imapHost,
        _imapPort,
        isSecure: true,
      );

      await client.login(email, appPassword);

      // 2. Select INBOX
      await client.selectInbox();

      // 3. Search unseen (unread) messages
      final searchResult = await client.searchMessages(
        searchCriteria: 'UNSEEN',
      );

      final sequence = searchResult.matchingSequence;
      if (sequence == null || sequence.isEmpty) {
        await client.logout();
        return MailResult(
          success: true,
          count: 0,
        );
      }

      final totalUnread = sequence.length;

      // 4. Quantity restriction logic
      MessageSequence targetSequence;
      int processedCount;

      if (!isPro && totalUnread > 50) {
        // Free tier: Take latest 50 messages
        final allIds = sequence.toList();
        final latest50 = allIds.length > 50
            ? allIds.sublist(allIds.length - 50)
            : allIds;
        targetSequence = MessageSequence();
        for (final id in latest50) {
          targetSequence.add(id);
        }
        processedCount = latest50.length;
      } else {
        // Pro tier or <= 50 emails
        targetSequence = sequence;
        processedCount = totalUnread;
      }

      // 5. Mark as Seen (\Seen)
      await client.markSeen(targetSequence);

      // 6. Disconnect
      await client.logout();

      return MailResult(
        success: true,
        count: processedCount,
      );
    } catch (e) {
      return MailResult(
        success: false,
        errorMessage: 'IMAP通信エラー: ${e.toString()}',
      );
    } finally {
      if (client.isConnected) {
        await client.disconnect();
      }
    }
  }
}
