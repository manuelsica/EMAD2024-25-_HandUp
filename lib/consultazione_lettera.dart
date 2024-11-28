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

  const ConsultazioneLettera({Key? key, required this.lettera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool mostraFrecciaSinistra = lettera != 'A';
    bool mostraFrecciaDestra = lettera != 'Z';
    
    
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
                    if (mostraFrecciaSinistra)
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textColor1),
                        iconSize: 40,
                        onPressed: () {
                          // Azione freccia sinistra
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
                    if (mostraFrecciaDestra)
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: AppColors.textColor1),
                        iconSize: 40,
                        onPressed: () {
                          // Azione freccia destra
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
                // Riquadro descrizione
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textColor2, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vitae posuere purus egestas.',
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