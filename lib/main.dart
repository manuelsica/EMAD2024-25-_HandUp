// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Socket e Provider
import 'socket_service.dart';
import 'lobby_provider.dart';

// Schermate varie
import 'app_colors.dart';
import 'intro_screen.dart';
import 'login.dart';
import 'registration.dart';
import 'animated_button.dart';

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
      // Avviamo l'app con MultiProvider che espone
      // sia SocketService che LobbyProvider a tutti i widget
      MultiProvider(
        providers: [
          Provider<SocketService>(
            create: (_) => SocketService(),
            dispose: (_, socketService) => socketService.dispose(),
          ),
          ChangeNotifierProxyProvider<SocketService, LobbyProvider>(
            create: (context) {
              final socketService = Provider.of<SocketService>(context, listen: false);
              return LobbyProvider(socketService: socketService);
            },
            update: (context, socketService, previous) {
              return previous ?? LobbyProvider(socketService: socketService);
            },
          ),
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
      title: 'HandUp',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPageScreen(),
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginPage(),
        '/registration': (context) => const RegistrationPage(),
        // Aggiungi qui le altre route che ti servono
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => false, // Impedisce chiusura app col tasto back
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  margin: EdgeInsets.only(bottom: screenHeight * 0.05),
                  child: Image.asset(
                    'assets/logo_handup.png',
                    width: screenWidth,
                    height: screenHeight * 0.4,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Icon(
                        Icons.error,
                        size: screenWidth * 0.8,
                        color: Colors.red,
                      );
                    },
                  ),
                ),

                // Inizia Ora
                AnimatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/intro');
                  },
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
                            const Color.fromARGB(110, 214, 57, 196),
                            const Color.fromARGB(110, 255, 0, 208),
                            const Color.fromARGB(110, 140, 53, 232),
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
                          Navigator.pushNamed(context, '/intro');
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

                // Login
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: AppColors.gradientText('Login', screenWidth * 0.04),
                ),

                // Registrati
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
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
