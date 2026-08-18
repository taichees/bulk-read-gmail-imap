import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/env_config.dart';
import 'providers/auth_provider.dart';
import 'providers/mail_provider.dart';
import 'providers/purchase_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If environmental configuration file is missing/not passed via --dart-define-from-file
    if (!EnvConfig.isConfigured) {
      return MaterialApp(
        title: 'エラー - 設定ファイル不足',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const EnvErrorScreen(),
      );
    }

    return MultiProvider(
      providers: [
        // 1. PurchaseProvider must be initialized first so AuthProvider can access it
        ChangeNotifierProvider(
          create: (_) => PurchaseProvider()..init(),
        ),
        // 2. AuthProvider initialized with identity linkage callback
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider();
            final purchaseProvider = context.read<PurchaseProvider>();
            authProvider.checkSavedCredentials(
              onUserIdentified: (email) {
                purchaseProvider.identifyUser(email);
              },
            );
            return authProvider;
          },
        ),
        // 3. MailProvider
        ChangeNotifierProvider(
          create: (_) => MailProvider(),
        ),
      ],
      child: MaterialApp(
        title: '一括既読プロ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF434F),
            surface: Color(0xFF000000),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Screen displayed when --dart-define-from-file=config/env.dev.json is missing
class EnvErrorScreen extends StatelessWidget {
  const EnvErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 40,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '環境設定ファイルが見つかりません',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '`--dart-define-from-file` にて設定ファイル（config/env.dev.json または env.prod.json）が指定されていません。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFAAAAAA),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '【起動コマンド】',
                      style: TextStyle(
                        color: Color(0xFFFF434F),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    SelectableText(
                      'flutter run --dart-define-from-file=config/env.dev.json',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Authentication Gate switching between LoginScreen and MainScreen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check entitlement state on app foreground (refund/revocation check)
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        context.read<PurchaseProvider>().checkProStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.status == AuthStatus.uninitialized ||
        (authProvider.isLoading && authProvider.credentials == null)) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFF434F),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                '読み込み中...',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
