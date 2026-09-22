import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/module_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';

class OpooboApp extends StatefulWidget {
  const OpooboApp({super.key});

  @override
  State<OpooboApp> createState() => _OpooboAppState();
}

class _OpooboAppState extends State<OpooboApp> {
  AuthState? _lastAuthState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);

    if (auth.state != _lastAuthState) {
      _lastAuthState = auth.state;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final modules = Provider.of<ModuleProvider>(context, listen: false);
        if (auth.state == AuthState.authenticated) {
          modules.loadModules();
        } else if (auth.state == AuthState.unauthenticated) {
          modules.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp(
      title: 'OPOOBO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.state == AuthState.initial ||
              auth.state == AuthState.loading) {
            return const SplashScreen();
          }

          if (auth.state != AuthState.authenticated) {
            return const LoginScreen();
          }

          // Authenticated → straight to home (auto-linked modules)
          return const HomeScreen();
        },
      ),
    );
  }
}
