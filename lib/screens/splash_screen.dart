import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadToken();

    // Optional: delay to show splash for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark brown/black background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container with circular background
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF5E6E0), // Light pink/cream background
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Needle illustration
                    Transform.rotate(
                      angle: -0.5, // Slight rotation for the needle
                      child: Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513), // Brown color for needle
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Thread curve (simplified as a small circle)
                    Positioned(
                      top: 35,
                      left: 45,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B4513),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Needle eye
                    Positioned(
                      top: 52,
                      right: 35,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF8B4513),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Brand name
            const Text(
              'CASA DARZI',
              style: TextStyle(
                color: Color(0xFFF5E6E0), // Light cream color
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 8.0,
                fontFamily: 'serif', // You can change this to a custom font
              ),
            ),

            const SizedBox(height: 12),

            // Tagline
            const Text(
              'WHERE STYLE COMES HOME',
              style: TextStyle(
                color: Color(0xFFB8A898), // Slightly darker cream
                fontSize: 12,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
                fontFamily: 'serif', // You can change this to a custom font
              ),
            ),

            const SizedBox(height: 80),

            // Loading indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFF5E6E0), // Light cream color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}