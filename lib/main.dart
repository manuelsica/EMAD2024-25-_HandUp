// lib/main.dart

import 'dart:math';
import "dart:io";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Importa Provider
import 'package:google_fonts/google_fonts.dart';
import 'socket_service.dart';
import 'sidemenu.dart';
import 'game_screen_spelling.dart';
import 'app_colors.dart';
import 'modalita_screen.dart';
import 'login.dart';
import 'registration.dart';
import 'intro_screen.dart';
import "animated_button.dart";
import 'risultati_partita.dart'; // Assicurati di avere questa schermata

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          Provider<SocketService>(
            create: (_) => SocketService(),
            dispose: (_, socketService) => socketService.dispose(),
          ),
          // Aggiungi altri provider se necessario
        ],
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandUp App', // Aggiungi un titolo per la tua app
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LandingPageScreen(),
      debugShowCheckedModeBanner: false, // Rimuove il debug banner
    );
  }
}

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ottieni le dimensioni dello schermo
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo container
                Container(
                  margin: EdgeInsets.only(bottom: screenHeight * 0.05),
                  child: Image.asset(
                    'assets/logo_handup.png',
                    width: screenWidth * 1,
                    height: screenHeight * 0.4,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Icon(Icons.error, size: screenWidth * 0.8, color: Colors.red);
                    },
                  ),
                ),

                // Start Now Button
                AnimatedButton(
                  onPressed: () {},
                  isLocked: false,
                  child: Container(
                    width: screenWidth * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textColor1.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(110, 214, 57, 196),
                            Color.fromARGB(110, 255, 0, 208),
                            Color.fromARGB(110, 140, 53, 232)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                            vertical: screenHeight * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () {
                          // Naviga alla schermata IntroScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const IntroScreen()),
                          );
                        },
                        child: Text(
                          'Inizia Ora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Login Text Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: AppColors.gradientText('Login', screenWidth * 0.04),
                ),

                // Registrati Text Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationPage()),
                    );
                  },
                  child: AppColors.gradientText('Registrati', screenWidth * 0.04),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}