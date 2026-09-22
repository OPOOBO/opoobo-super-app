import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/module_provider.dart';
import 'providers/bus_booking_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/payment_method_provider.dart';
import 'providers/address_provider.dart';
import 'providers/saved_location_provider.dart';
import 'providers/security_provider.dart';
import 'providers/flutterwave_auth_provider.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => ModuleProvider()..loadModules()),
        ChangeNotifierProvider(create: (_) => BusBookingProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()..loadStats()),
        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => SavedLocationProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => FlutterwaveAuthProvider()),
      ],
      child: const OpooboApp(),
    ),
  );
}
