// lib/risultati_partita.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sidemenu.dart';
import 'app_colors.dart';
import 'select_multiplayer.dart';
import 'top_bar.dart';

class RisultatiPartitaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: SideMenu(),
      appBar: AppBar(
        title: const Text("Risultati Partita"),
        backgroundColor: Colors.purple,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Titolo con gradiente
                  AppColors.gradientText(
                    "Risultati della Partita",
                    24, // Dimensione del font
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // InfoBox: Tempo di Gioco
                  InfoBox(
                    label: "Tempo Partita",
                    value: "05:00",
                    icon: Icons.hourglass_bottom,
                    color: Colors.pinkAccent,
                  ),
                  SizedBox(height: screenHeight * 0.016),

                  // InfoBox: Punti Esperienza
                  InfoBox(
                    label: "Punti Esperienza",
                    value: "50",
                    icon: Icons.star,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(height: screenHeight * 0.016),

                  // Progressi con gradiente
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 66, 66, 80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart, color: Colors.pinkAccent),
                            SizedBox(width: screenWidth * 0.008),
                            AppColors.gradientText(
                              "Progressi", // Testo a sinistra
                              18, // Dimensione del font
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Usa il gradiente per "Punti Totali"
                            AppColors.gradientText(
                              "Punti Totali:", // Testo a sinistra
                              20, // Dimensione del font
                            ),
                            AppColors.gradientText(
                              "900 + 50 = 950", // Testo a destra
                              20, // Dimensione del font
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Usa il gradiente per "Streak Consecutive"
                            AppColors.gradientText(
                              "Streak Consecutive:", // Testo a sinistra
                              20, // Dimensione del font
                            ),
                            AppColors.gradientText(
                              "5", // Testo a destra
                              20, // Dimensione del font
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Pulsanti
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pulsante "Gioca di Nuovo" avvolto in Flexible
                      Flexible(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ), // Ridotto l'horizontal padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            // Azione per il pulsante "Gioca di Nuovo"
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModalitaScreen(lobbyId: ""),
                              ), // Sostituisci con l'ID appropriato
                            );
                          },
                          child: Text(
                            "Gioca di Nuovo",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.016), // Spazio tra i pulsanti

                      // Pulsante "Torna alle Modalità" avvolto in Flexible
                      Flexible(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.containerBorderColor4,
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ), // Ridotto l'horizontal padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModalitaScreen(lobbyId: ""),
                              ), // Sostituisci con l'ID appropriato
                            );
                          },
                          child: Text(
                            "Torna alle Modalità",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget per le informazioni (Tempo, Punti Esperienza, ecc.)
class InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const InfoBox({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 66, 66, 80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: screenWidth * 0.008),
              AppColors.gradientText(
                label, // Testo della label
                16, // Dimensione del font
              ),
            ],
          ),
          AppColors.gradientText(
            value, // Testo del valore
            18, // Dimensione del font
          ),
        ],
      ),
    );
  }
}