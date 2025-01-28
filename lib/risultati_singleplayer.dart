import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import "sidemenu.dart";
import "app_colors.dart";
import "top_bar.dart";
import "difficulty_selection.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "selezione_gioco.dart";

// Classe per i risultati della partita
class RisultatiPartitaScreen extends StatefulWidget {
  // Parametri per i risultati della partita
  final int correctAnswers;
  final int totalQuestions = 10;
  final int gameTime;
  final String gameMode;

  const RisultatiPartitaScreen({
    Key? key,
    required this.correctAnswers,
    required this.gameMode,
    // required this.totalQuestions,
    required this.gameTime,
  }) : super(key: key);

  @override
  _RisultatiPartitaScreenState createState() => _RisultatiPartitaScreenState();
}

class _RisultatiPartitaScreenState extends State<RisultatiPartitaScreen> {
  // Storage sicuro per i dati dell'utente
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Variabili di stato
  int totalPoints = 0;
  int streak = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Carica i dati dell'utente dallo storage
  Future<void> _loadUserData() async {
    try {
      // Recupera i punti totali e la streak dallo storage
      String? pointsStr = await storage.read(key: 'points');
      // String? streakStr = await storage.read(key: 'streak');

      setState(() {
        totalPoints = int.tryParse(pointsStr ?? '0') ?? 0;
        // streak = int.tryParse(streakStr ?? '0') ?? 0;
        isLoading = false;
      });

      // Calcola e salva i nuovi punti
      await _calculateAndSavePoints();
    } catch (e) {
      print('Errore nel caricamento dei dati: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calcola e salva i nuovi punti
  Future<void> _calculateAndSavePoints() async {
    // Calcola i punti esperienza basati sulle risposte corrette
    int experiencePoints = 0;
    if (widget.gameMode == "spelling") {
        experiencePoints = widget.correctAnswers * 10;
    } else if(widget.gameMode == "hangman") {
        experiencePoints = widget.correctAnswers * 20;
    }

    // Aggiorna i punti totali
    int newTotalPoints = totalPoints + experiencePoints;

    // Aggiorna la streak
    // int newStreak =
    //     widget.correctAnswers == widget.totalQuestions ? streak + 1 : 0;

    // Salva i nuovi valori
    // await storage.write(key: 'points', value: newTotalPoints.toString());
    // await storage.write(key: 'streak', value: newStreak.toString());

    setState(() {
      totalPoints = newTotalPoints;
      // streak = newStreak;
    });
  }

  // Gestisce il pulsante "Gioca di nuovo"
  void _handlePlayAgain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DifficultySelectionScreen(gameMode: widget.gameMode),
      ),
    );
  }

  // Gestisce il pulsante "Torna alle modalità"
  void _handleBackToModes() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: SideMenu(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titolo
                        AppColors.gradientText(
                          "Risultati della Partita",
                          24,
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Tempo di gioco
                        InfoBox(
                          label: "Tempo Partita",
                            value: "${(widget.gameTime ~/ 60).toString().padLeft(2, '0')}:${(widget.gameTime % 60).toString().padLeft(2, '0')}",
                          icon: Icons.hourglass_bottom,
                          color: Colors.pinkAccent,
                        ),
                        SizedBox(height: screenHeight * 0.016),

                        // Punti esperienza
                        InfoBox(
                          label: "Punti Esperienza",
                          value: (widget.gameMode == "spelling" ? widget.correctAnswers * 10 : widget.correctAnswers * 20).toString(),
                          icon: Icons.star,
                          color: Colors.orangeAccent,
                        ),
                        SizedBox(height: screenHeight * 0.016),

                        // Box dei progressi
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
                                  Icon(Icons.bar_chart,
                                      color: Colors.pinkAccent),
                                  SizedBox(width: screenWidth * 0.008),
                                  AppColors.gradientText(
                                    "Progressi",
                                    18,
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.012),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AppColors.gradientText(
                                    "Punti Totali:",
                                    20,
                                  ),
                                  AppColors.gradientText(
                                    "$totalPoints + ${widget.correctAnswers * 10} = ${totalPoints + widget.correctAnswers * 10}",
                                    20,
                                  ),
                                ],
                              ),
                              // SizedBox(height: screenHeight * 0.012),
                              // Row(
                              //   mainAxisAlignment:
                              //       MainAxisAlignment.spaceBetween,
                              //   children: [
                              //     AppColors.gradientText(
                              //       "Streak Consecutive:",
                              //       20,
                              //     ),
                              //     AppColors.gradientText(
                              //       streak.toString(),
                              //       20,
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ),

                        Spacer(),

                        // Pulsanti
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _handlePlayAgain,
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
                            SizedBox(width: screenWidth * 0.016),
                            Flexible(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.containerBorderColor4,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _handleBackToModes,
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
          ),
        ],
      ),
    );
  }
}

// Widget per le box informative
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
                label,
                16,
              ),
            ],
          ),
          AppColors.gradientText(
            value,
            18,
          ),
        ],
      ),
    );
  }
}
