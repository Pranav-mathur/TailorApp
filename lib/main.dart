import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tailor_app/screens/upgrade_profile_screen.dart';

import 'providers/global_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';  // ✅ ADD THIS - New provider
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/kyc_verification_screen.dart';
import 'screens/business_details_screen.dart';
import 'screens/location_picker_screen.dart';
import 'screens/add_address_screen.dart';
import 'screens/services_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_details_screen.dart';
import 'screens/past_orders_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/bank_details_screen.dart';
import 'screens/set_location_screen.dart';  // ✅ ADD THIS - New OpenStreetMap screen

void main() async {
  // Ensure Flutter is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style (status bar and navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => GlobalProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casa Darzi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.latoTextTheme(),
        // Add scaffold background color to match splash
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpVerificationScreen(phoneNumber: ''),
        '/kyc': (context) => const KycVerificationScreen(),
        '/business': (context) => const BusinessDetailsScreen(),
        '/location-picker': (context) => const LocationPickerScreen(),
        '/set-location': (context) => const SetLocationScreen(),
        '/add-address': (context) => const AddAddressScreen(),
        '/services': (context) => const ServicesScreen(),
        '/home': (context) => const HomeScreen(),
        '/order-details': (context) => const OrderDetailsScreen(),
        '/past-orders': (context) => const PastOrdersScreen(),
        '/my-profile': (context) => const MyProfileScreen(),
        '/bank-details': (context) => const BankDetailsScreen(),
        '/upgrade-profile': (context) => const UpgradeProfileScreen(tailorId: '', token: ''),
      },
    );
  }
}