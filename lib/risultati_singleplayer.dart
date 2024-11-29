import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:hand_up_interface/main.dart'; // Rimuovilo se non necessario
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Risultati Partita',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: RisultatiPartitaScreen(),
    );
  }
}

class RisultatiPartitaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
     return Scaffold(
      drawer: SideMenu(),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header con menu e profilo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (BuildContext context) {
                          return IconButton(
                            icon: Icon(Icons.menu, color: Colors.white),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          );
                        },
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Text(
                              'U',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Username',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '000 Punti',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Corpo principale della schermata
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titolo
                        Text(
                          "Risultati della Partita",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 30),

                        // InfoBox: Tempo di Gioco
                        InfoBox(
                          label: "Tempo Partita",
                          value: "00:47",
                          icon: Icons.hourglass_bottom,
                          color: Colors.pinkAccent,
                        ),
                        SizedBox(height: 16),

                        // InfoBox: Punti Esperienza
                        InfoBox(
                          label: "Punti Esperienza",
                          value: "7",
                          icon: Icons.star,
                          color: Colors.orangeAccent,
                        ),
                        SizedBox(height: 16),

                        // Progressi
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.textColor3,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bar_chart, color: Colors.pinkAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    "Progressi",
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Punti Totali: 900 + 7 = 907",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                "Streak Consecutive: 5",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Spacer(),

                        // Pulsante "Gioca di Nuovo"
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              // Azione per il pulsante
                            },
                            child: Text(
                              "Gioca di Nuovo",
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: AppColors.textColor3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}