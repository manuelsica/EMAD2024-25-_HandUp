import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';
import "registration.dart";

class IntroScreen extends StatelessWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: SideMenu(),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(builder: (BuildContext context) {
                      //Icona della barra laterale
                      return IconButton(
                        icon: CustomPaint(
                          size: Size(24, 24),
                          painter: GradientIconPainter(
                            icon: Icons.menu,
                            gradient: AppColors.textGradient,
                          ),
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    }),
                    //Avatar e Username
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child:
                              Text('U', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'USERNAME',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '000 Punti',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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
                                    //Testo con Shader Mask per gradiente
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
                                      )
                                    ),
                                    SizedBox(height: 10),
                                    //Blocco di testo
                                    Container(
                                      width: screenWidth * 0.55,
                                      child: Text(
                                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: screenWidth * 0.035,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              //Immagine dei cubi
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
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        // Sezioni delle varie categorie
                        _buildSection(
                          context,
                          'Vocali',
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                          screenWidth,
                        ),
                        //Separatore per dare il giusto spazio tra sezioni
                        SizedBox(height: 20),

                        _buildSection(
                          context,
                          'Consonanti',
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                          screenWidth,
                        ),

                        SizedBox(height: 20),

                        _buildSection(
                          context,
                          'Parole',
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita e posuere purus egestas.',
                          screenWidth,
                        ),
                        SizedBox(height: 20),

                        //Pulsante di Registrazione
                        Center(
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
                                  // Add navigation logic here
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

                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  //Funzione per la creazione di una sezione
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