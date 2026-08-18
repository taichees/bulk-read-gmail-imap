import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkSavedCredentials(),
        ),
        ChangeNotifierProvider(
          create: (_) => MailProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PurchaseProvider()..init(),
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

/// Authentication Gate switching between LoginScreen and MainScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
