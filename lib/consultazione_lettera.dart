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
    'F': 'Testo relativo alla lettera F. Da inserire procedura di riproduzione della lettera F. Per riprodurre la lettera F, Forma un cerchio con il pollice e l\'indice, toccandoli tra loro. Le altre dita sono dritte e rivolte verso l\'alto.',
    'G': 'Testo relativo alla lettera G. Da inserire procedura di riproduzione della lettera G. Per riprodurre la lettera G, Chiudi le dita ad eccezione dell\'indice e del pollice, che sono estesi orizzontalmente come se indicassero lateralmente.',
    'H': 'Testo relativo alla lettera H. Da inserire procedura di riproduzione della lettera H. Per riprodurre la lettera H, Tieni il medio e l\'indice estesi e uniti, formando una "V" sdraiata. Piega le altre dita verso il palmo e tieni il pollice piegato sopra di esse.',
    'I': 'Testo relativo alla lettera I. Da inserire procedura di riproduzione della lettera I. Per riprodurre la lettera I, Estendi solo il mignolo verso l\'alto, piegando tutte le altre dita verso il palmo e mantenendo il pollice appoggiato sulle dita.',
    'J': 'Testo relativo alla lettera J. Da inserire procedura di riproduzione della lettera J. Per riprodurre la lettera J, Come per la lettera "I", estendi il mignolo. Poi usa il mignolo per tracciare nell\'aria una curva simile a una "J".',
    'K': 'Testo relativo alla lettera K. Da inserire procedura di riproduzione della lettera K. Per riprodurre la lettera K, Tieni l\'indice e il medio aperti formando una "V". Piega il pollice verso il basso, appoggiandolo tra l\'indice e il medio. Piega le altre dita verso il palmo.',
    'L': 'Testo relativo alla lettera L. Da inserire procedura di riproduzione della lettera L. Per riprodurre la lettera L, Forma una "L" con il pollice e l\'indice estesi, mentre le altre dita rimangono piegate verso il palmo.',
    'M': 'Testo relativo alla lettera M. Da inserire procedura di riproduzione della lettera M. Per riprodurre la lettera M, Piega tutte le dita verso il palmo e posiziona il pollice sopra di esse. Assicurati che il pollice sia coperto da tre dita (indice, medio e anulare).',
    'N': 'Testo relativo alla lettera N. Da inserire procedura di riproduzione della lettera N. Per riprodurre la lettera N, Simile alla "M", ma il pollice è coperto solo da due dita (indice e medio).',
    'O': 'Testo relativo alla lettera O. Da inserire procedura di riproduzione della lettera O. Per riprodurre la lettera O, Forma un cerchio completo con tutte le dita, unendo i polpastrelli.',
    'P': 'Testo relativo alla lettera P. Da inserire procedura di riproduzione della lettera P. Per riprodurre la lettera P, Come per la "K", ma con il palmo rivolto verso il basso.',
    'Q': 'Testo relativo alla lettera Q. Da inserire procedura di riproduzione della lettera Q. Per riprodurre la lettera Q, Chiudi le dita e tieni il pollice e l\'indice estesi. Poi abbassa il pollice verso il basso come per indicare.',
    'R': 'Testo relativo alla lettera R. Da inserire procedura di riproduzione della lettera R. Per riprodurre la lettera R, Incrocia l\'indice e il medio, mantenendo le altre dita piegate verso il palmo.',
    'S': 'Testo relativo alla lettera S. Da inserire procedura di riproduzione della lettera S. Per riprodurre la lettera S, Forma un pugno chiuso con tutte le dita piegate verso il palmo, e il pollice che si appoggia sopra.',
    'T': 'Testo relativo alla lettera T. Da inserire procedura di riproduzione della lettera T. Per riprodurre la lettera T, Forma un pugno e posiziona il pollice tra l\'indice e il medio.',
    'U': 'Testo relativo alla lettera U. Da inserire procedura di riproduzione della lettera U. Per riprodurre la lettera U, Estendi l\'indice e il medio verso l\'alto, unendoli. Piega le altre dita verso il palmo e tieni il pollice piegato.',
    'V': 'Testo relativo alla lettera V. Da inserire procedura di riproduzione della lettera V. Per riprodurre la lettera V, Estendi l\'indice e il medio verso l\'alto, tenendoli separati a formare una "V". Piega le altre dita verso il palmo.',
    'W': 'Testo relativo alla lettera W. Da inserire procedura di riproduzione della lettera W. Per riprodurre la lettera W, Estendi il pollice, l\'indice e il medio verso l\'alto, formando una "W". Piega l\'anulare e il mignolo verso il palmo.',
    'X': 'Testo relativo alla lettera X. Da inserire procedura di riproduzione della lettera X. Per riprodurre la lettera X, Piega l\'indice verso il palmo, formando una curva simile a un uncino. Piega le altre dita verso il palmo e tieni il pollice sopra.',
    'Y': 'Testo relativo alla lettera Y. Da inserire procedura di riproduzione della lettera Y. Per riprodurre la lettera Y, Estendi il pollice e il mignolo in fuori, mentre pieghi le altre dita verso il palmo. La forma ricorda il simbolo del "telefono".',
    'Z': 'Testo relativo alla lettera Z. Da inserire procedura di riproduzione della lettera Z. Per riprodurre la lettera Z, Usa l\'indice per tracciare una "Z" nell\'aria, mantenendo le altre dita piegate verso il palmo.',
  };

 // Mappa per le immagini dinamiche
  final Map<String, String> immaginiLettere = {
    'A': 'assets/hand_icon.png',
    'B': 'assets/hand_icon.png',
    'C': 'assets/hand_icon.png',
    'D': 'assets/hand_icon.png',
    'E': 'assets/hand_icon.png',
    'F': 'assets/hand_icon.png',
    'G': 'assets/hand_icon.png',
    'H': 'assets/hand_icon.png',
    'I': 'assets/hand_icon.png',
    'J': 'assets/hand_icon.png',
    'K': 'assets/hand_icon.png',
    'L': 'assets/hand_icon.png',
    'M': 'assets/hand_icon.png',
    'N': 'assets/hand_icon.png',
    'O': 'assets/hand_icon.png',
    'P': 'assets/hand_icon.png',
    'Q': 'assets/hand_icon.png',
    'R': 'assets/hand_icon.png',
    'S': 'assets/hand_icon.png',
    'T': 'assets/hand_icon.png',
    'U': 'assets/hand_icon.png',
    'V': 'assets/hand_icon.png',
    'W': 'assets/hand_icon.png',
    'X': 'assets/hand_icon.png',
    'Y': 'assets/hand_icon.png',
    'Z': 'assets/hand_icon.png',
   
  };



  ConsultazioneLettera({Key? key, required this.lettera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool mostraFrecciaSinistra = lettera != 'A';
    bool mostraFrecciaDestra = lettera != 'Z';
     String testoLettera = letterTexts[lettera] ?? 'Testo non disponibile per la lettera $lettera.';
final String? immagineCorrente = immaginiLettere[lettera]; // Ottieni il percorso immagine dalla mappa

   
    
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
                // Layout immagine con frecce
                Row(
                  children: [
                    // Freccia sinistra
                    if (mostraFrecciaSinistra)
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textColor1),
                        iconSize: 40,
                        onPressed: () {
                          String letteraPrecedente =
                              String.fromCharCode(lettera.codeUnitAt(0) - 1);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ConsultazioneLettera(lettera: letteraPrecedente),
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
                          child: immagineCorrente != null
                              ? Image.asset(
                                  immagineCorrente, // Percorso immagine
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                )
                              : Text(
                                  "Immagine non trovata",
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
                          String letteraSuccessiva =
                              String.fromCharCode(lettera.codeUnitAt(0) + 1);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ConsultazioneLettera(lettera: letteraSuccessiva),
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
                // Riquadro descrizione
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textColor2, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    testoLettera,
                    style: GoogleFonts.roboto(
                      color: const Color.fromARGB(189, 255, 255, 255),
                      fontSize: 17,
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