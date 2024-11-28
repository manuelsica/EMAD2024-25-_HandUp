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
      title: 'Consultazione Lettera',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleziona una Lettera')),
      body: Center(child: Text('Benvenuto!')),
    );
  }
}

class ConsultazioneLettera extends StatelessWidget {
  final String lettera;


  final Map<String, String> letterTexts = {
    'A': 'Testo relativo alla lettera A. Da inserire procedura di riproduzione della lettera A. Per riprodurre la lettera A, chiudere la mano a pugno, estendere il pollice in avanti',
    'B': 'Testo relativo alla lettera B. Da inserire procedura di riproduzione della lettera B. Per riprodurre la lettera B, tenere tutte le dita tese e unite tra loro e piegare il pollice in avanti sul palmo',
    'C': 'Testo relativo alla lettera C. Da inserire procedura di riproduzione della lettera C. Per riprodurre la lettera C, aprire la mano formando una C. Quindi pollice e dita sono arcuate in modo da formare una C',
    'D': 'Testo relativo alla lettera D. Da inserire procedura di riproduzione della lettera D. Per riprodurre la lettera D, tenere tutte le dita chiuse a pugno tranne l\'indice che è teso verso l\'alto',
    'E': 'Testo relativo alla lettera E. Da inserire procedura di riproduzione della lettera E. Per riprodurre la lettera E, tenere tutte le dita piegate verso il palmo.',
    'F': 'Testo relativo alla lettera F. Da inserire procedura di riproduzione della lettera F',
    'G': 'Testo relativo alla lettera G. Da inserire procedura di riproduzione della lettera G',
    'H': 'Testo relativo alla lettera H. Da inserire procedura di riproduzione della lettera H',
    'I': 'Testo relativo alla lettera I. Da inserire procedura di riproduzione della lettera I',
    'J': 'Testo relativo alla lettera J. Da inserire procedura di riproduzione della lettera J',
    'K': 'Testo relativo alla lettera K. Da inserire procedura di riproduzione della lettera K',
    'L': 'Testo relativo alla lettera L. Da inserire procedura di riproduzione della lettera L',
    'M': 'Testo relativo alla lettera M. Da inserire procedura di riproduzione della lettera M',
    'N': 'Testo relativo alla lettera N. Da inserire procedura di riproduzione della lettera N',
    'O': 'Testo relativo alla lettera O. Da inserire procedura di riproduzione della lettera O',
    'P': 'Testo relativo alla lettera P. Da inserire procedura di riproduzione della lettera P',
    'Q': 'Testo relativo alla lettera Q. Da inserire procedura di riproduzione della lettera Q',
    'R': 'Testo relativo alla lettera R. Da inserire procedura di riproduzione della lettera R',
    'S': 'Testo relativo alla lettera S. Da inserire procedura di riproduzione della lettera S',
    'T': 'Testo relativo alla lettera T. Da inserire procedura di riproduzione della lettera T',
    'U': 'Testo relativo alla lettera U. Da inserire procedura di riproduzione della lettera U',
    'V': 'Testo relativo alla lettera V. Da inserire procedura di riproduzione della lettera V',
    'W': 'Testo relativo alla lettera W. Da inserire procedura di riproduzione della lettera W',
    'X': 'Testo relativo alla lettera X. Da inserire procedura di riproduzione della lettera X',
    'Y': 'Testo relativo alla lettera Y. Da inserire procedura di riproduzione della lettera Y',
    'Z': 'Testo relativo alla lettera Z. Da inserire procedura di riproduzione della lettera Z',
  };

  ConsultazioneLettera({Key? key, required this.lettera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool mostraFrecciaSinistra = lettera != 'A';
    bool mostraFrecciaDestra = lettera != 'Z';
     String testoLettera = letterTexts[lettera] ?? 'Testo non disponibile per la lettera $lettera.';

    
   return Scaffold(
      drawer: SideMenu(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor, // Sfondo mantenuto dal precedente codice
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header (rimasto invariato)
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
                Spacer(),
                // Layout immagine placeholder con le frecce
                Row(
                  children: [
                    // Freccia sinistra
                    if (mostraFrecciaSinistra)
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textColor1),
                        iconSize: 40,
                        onPressed: () {
                          // Navigazione alla lettera precedente
                          String letteraPrecedente = String.fromCharCode(lettera.codeUnitAt(0) - 1);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConsultazioneLettera(lettera: letteraPrecedente),
                            ),
                          );
                        },
                      )
                    else
                      SizedBox(width: 40), // Placeholder per la freccia sinistra
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            "Placeholder Immagine",
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = AppColors.textGradient.createShader(
                                  Rect.fromLTWH(0, 0, screenWidth, 0),
                                ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Freccia destra
                    if (mostraFrecciaDestra)
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: AppColors.textColor1),
                        iconSize: 40,
                        onPressed: () {
                          // Navigazione alla lettera successiva
                          String letteraSuccessiva = String.fromCharCode(lettera.codeUnitAt(0) + 1);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConsultazioneLettera(lettera: letteraSuccessiva),
                            ),
                          );
                        },
                      )
                    else
                      SizedBox(width: 40), // Placeholder per la freccia destra
                  ],
                ),
                SizedBox(height: 16),
                // Titolo "Lettera A"
                Text(
                  'Lettera $lettera',
                  style: GoogleFonts.roboto(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = AppColors.textGradient.createShader(
                        Rect.fromLTWH(0, 0, screenWidth, 0),
                      ),
                  ),
                ),
                SizedBox(height: 20),
                // Riquadro descrizione (testo dinamico)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textColor2, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    testoLettera, // Testo dinamico basato sulla lettera
                    style: GoogleFonts.roboto(
                      color: AppColors.textColor2,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}