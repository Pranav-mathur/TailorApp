import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';


import 'providers/global_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/auth_provider.dart';
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

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => GlobalProvider()),
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
      ),
      initialRoute: '/splash', // Start with splash screen
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpVerificationScreen(phoneNumber: ''),
        '/kyc': (context) => const KycVerificationScreen(),
        '/business': (context) => const BusinessDetailsScreen(),
        '/location-picker': (context) => const LocationPickerScreen(),
        '/add-address': (context) => const AddAddressScreen(),
        '/services': (context) => const ServicesScreen(),
        '/home': (context) => const HomeScreen(),
        '/order-details': (context) => const OrderDetailsScreen(),
        '/past-orders': (context) => const PastOrdersScreen(),
        '/my-profile': (context) => const MyProfileScreen(),
        '/bank-details': (context) => const BankDetailsScreen(),
      },
    );
  }
}
