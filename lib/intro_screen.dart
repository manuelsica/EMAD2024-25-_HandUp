// lib/intro_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';
import "registration.dart";
import "top_bar.dart";
import "animated_button.dart";

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // Variabile per controllare se consentire il pop
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        if (_allowPop) {
          // Reset della variabile e consentiamo il pop
          _allowPop = false;
          return true;
        }
        // Blocchiamo il pop (impediamo lo swipe back)
        return false;
      },
      child: Scaffold(
        drawer: SideMenu(),
        drawerEnableOpenDragGesture: false, // Disabilita l'apertura del Drawer tramite swipe
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar senza callback per il pulsante di ritorno
                TopBar(
                  username: "USERNAME",
                  points: 1000,
                  showMenu: true,
                  showUser: false,
                ),
                // Blocco "Sblocca le funzionalità"
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Feature Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple.shade900.withOpacity(0.3),
                                  Colors.purple.shade800.withOpacity(0.3),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.textColor1.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Testo con Shader Mask per gradiente
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            AppColors.textGradient.createShader(bounds),
                                        child: Text(
                                          'Sblocca le funzionalità',
                                          style: TextStyle(
                                            color: AppColors.textColor1,
                                            fontSize: screenWidth * 0.07,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      // Blocco di testo
                                      Container(
                                        width: screenWidth * 0.55,
                                        child: Text(
                                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: screenWidth * 0.035,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Immagine dei cubi
                                Positioned(
                                  right: -60,
                                  bottom: -20,
                                  child: Transform.rotate(
                                    angle: -0.10,
                                    child: Opacity(
                                      opacity: 0.9,
                                      child: Image.asset(
                                        'assets/alphabet_cubes.png',
                                        width: screenWidth * 0.7,
                                        height: screenWidth * 0.7,
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
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          // Sezioni delle varie categorie
                          _buildSection(
                            context,
                            'Vocali',
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                            screenWidth,
                          ),
                          // Separatore per dare il giusto spazio tra sezioni
                          SizedBox(height: screenHeight * 0.02),

                          _buildSection(
                            context,
                            'Consonanti',
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                            screenWidth,
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          _buildSection(
                            context,
                            'Parole',
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                            screenWidth,
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Pulsante di Registrazione
                          AnimatedButton(
                            onPressed: () {},
                            isLocked: false,
                            child: Center(
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
                                      // Naviga alla schermata di Registrazione
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const RegistrationPage()),
                                      );
                                    },
                                    child: Text(
                                      'Registrati Ora',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Funzione per la creazione di una sezione
  Widget _buildSection(BuildContext context, String title, String description,
      double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.containerOpaqueColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 5,
            top: -15,
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.textGradient.createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
