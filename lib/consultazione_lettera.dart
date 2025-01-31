// lib/consultazione_lettera.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sidemenu.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'top_bar.dart';
import 'socket_service.dart'; 
import "consultazione.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Rimuove il banner di debug
      title: 'Consultazione Lettera',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  // Convertito in StatefulWidget
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService socketService = SocketService();
  final FlutterSecureStorage storage =
      const FlutterSecureStorage(); // Inizializza FlutterSecureStorage
  String username = "USERNAME"; // Questo valore verrà aggiornato dinamicamente
  int yourPoints = 0; // Questo valore verrà aggiornato dinamicamente
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    socketService.connect(); // Assicurati che la connessione sia stabilita
    _initializeUserData(); // Inizializza i dati utente
  }


  /// Inizializza i dati dell'utente recuperando l'username e i punti dalla storage o dal server
  Future<void> _initializeUserData() async {
    // Recupera l'username e i punti dalla memorizzazione locale
    String? storedUsername = await storage.read(key: 'username');
    String? pointsStr = await storage.read(key: 'points');
    int? storedPoints = pointsStr != null ? int.tryParse(pointsStr) : null;

    setState(() {
      username = storedUsername ?? "USERNAME";
      yourPoints = storedPoints ?? 0;
    });

    // Successivamente, recupera i dati dal server
    fetchUserData();
  }

  /// Recupera i dati dell'utente dal server
  Future<void> fetchUserData() async {
    final data = await socketService
        .fetchLeaderboard(); // Usa fetchLeaderboard o un endpoint appropriato
    if (data != null) {
      setState(() {
        // Aggiorna i dati ricevuti dal server
        yourPoints = data['your_points'] as int? ?? yourPoints;
        if (data['your_username'] != null &&
            data['your_username'].toString().isNotEmpty) {
          username = data['your_username'];
        }
        isLoading = false;
      });
    } else {
      // Gestisci l'errore come preferisci, ad esempio mostrando un messaggio
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Errore nel recupero dei dati utente. Riprova più tardi.')),
      );
    }
  }

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
              // App Bar con username e punti dinamici
              TopBar(
                username: username,
                points: yourPoints,
                showMenu: true,
                showUser: true,
              ),
              // Contenuto Principale
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Create Game Card
                      Container(
                        height: screenHeight * 0.15,
                        width: screenWidth * 0.9,
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: AppColors.textColor2,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Libreria di Consultazione',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColor2,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.04),
                                  Align(
                                    alignment: Alignment.center,
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
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.transparent,
                                            blurRadius: 20,
                                            spreadRadius: 4,
                                            offset: const Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Sezione Join Game
                      Text(
                        'Seleziona una Lettera',
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor1,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      // Lista delle Lettere (A-Z)
                      isLoading
                          ? Center(child: CircularProgressIndicator())
                          : Column(
                              children: List.generate(26, (index) {
                                // Genera una lettera a partire dall'indice
                                String lettera =
                                    String.fromCharCode(65 + index); // 65 è il codice ASCII di 'A'
                                return _buildLobbyItem(
                                  lettera: lettera,
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  context:
                                      context, // Passa il contesto per la navigazione
                                );
                              }),
                            ),
                      // Bottone Indietro
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLobbyItem({
    required String lettera,
    required double screenWidth,
    required double screenHeight,
    required BuildContext context, // Aggiunto per gestire Navigator
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsultazioneLettera(lettera: lettera),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.containerOpaqueColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scritta "LETTERA"
                  Text(
                    'LETTERA',
                    style: TextStyle(
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.bold,
                      color: AppColors
                          .textColor1, // Colore specificato nel TextStyle
                    ),
                  ),
                  SizedBox(
                      width:
                          screenWidth * 0.02), // Spaziatura tra "LETTERA" e la lettera
                  // Lettera specifica
                  Text(
                    lettera,
                    style: TextStyle(
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.bold,
                      color: AppColors
                          .textColor3, // Colore specificato nel TextStyle
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsultazioneLettera extends StatefulWidget {
  // Convertito in StatefulWidget
  final String lettera;

  const ConsultazioneLettera({Key? key, required this.lettera})
      : super(key: key);

  @override
  _ConsultazioneLetteraState createState() => _ConsultazioneLetteraState();
}

class _ConsultazioneLetteraState extends State<ConsultazioneLettera> {
  final SocketService socketService = SocketService();
  final FlutterSecureStorage storage =
      const FlutterSecureStorage(); // Inizializza FlutterSecureStorage
  String username = "USERNAME"; // Questo valore verrà aggiornato dinamicamente
  int yourPoints = 0; // Questo valore verrà aggiornato dinamicamente
  bool isLoading = true;

  // Stato corrente della lettera
  late String currentLettera;
  late String testoLettera;
  late String? immagineCorrente;

  // Chiavi per AnimatedSwitcher
  Key _letteraKey = UniqueKey();
  Key _testoKey = UniqueKey();
  Key _immagineKey = UniqueKey();

  // Variabile di stato per determinare la direzione della transizione
  bool _versoDestra = true;

  @override
  void initState() {
    super.initState();
    currentLettera = widget.lettera;
    testoLettera = letterTexts[currentLettera] ??
        'Testo non disponibile per la lettera $currentLettera.';
    immagineCorrente = immaginiLettere[currentLettera];
    socketService.connect(); // Assicurati che la connessione sia stabilita
    _initializeUserData(); // Inizializza i dati utente
  }


  /// Inizializza i dati dell'utente recuperando l'username e i punti dalla storage o dal server
  Future<void> _initializeUserData() async {
    // Recupera l'username e i punti dalla memorizzazione locale
    String? storedUsername = await storage.read(key: 'username');
    String? pointsStr = await storage.read(key: 'points');
    int? storedPoints = pointsStr != null ? int.tryParse(pointsStr) : null;

    setState(() {
      username = storedUsername ?? "USERNAME";
      yourPoints = storedPoints ?? 0;
    });

    // Successivamente, recupera i dati dal server
    fetchUserData();
  }

  /// Recupera i dati dell'utente dal server
  Future<void> fetchUserData() async {
    final data = await socketService
        .fetchLeaderboard(); // Usa fetchLeaderboard o un endpoint appropriato
    if (data != null) {
      setState(() {
        // Aggiorna i dati ricevuti dal server
        yourPoints = data['your_points'] as int? ?? yourPoints;
        if (data['your_username'] != null &&
            data['your_username'].toString().isNotEmpty) {
          username = data['your_username'];
        }
        isLoading = false;
      });
    } else {
      // Gestisci l'errore come preferisci, ad esempio mostrando un messaggio
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Errore nel recupero dei dati utente. Riprova più tardi.')),
      );
    }
  }

  /// Cambia la lettera corrente con animazione
  void _cambiaLettera(String nuovaLettera, bool versoDestra) {
    setState(() {
      currentLettera = nuovaLettera;
      testoLettera =
          letterTexts[nuovaLettera] ?? 'Testo non disponibile per la lettera $nuovaLettera.';
      immagineCorrente = immaginiLettere[nuovaLettera];

      // Imposta la direzione della transizione
      _versoDestra = versoDestra;

      // Aggiorna le chiavi per AnimatedSwitcher
      _letteraKey = UniqueKey();
      _testoKey = UniqueKey();
      _immagineKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool mostraFrecciaSinistra = currentLettera != 'A';
    bool mostraFrecciaDestra = currentLettera != 'Z';

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
                // TopBar con username e punti dinamici
                TopBar(
                  username: username,
                  points: yourPoints,
                  showMenu: true,
                  showUser: true,
                ),
                Spacer(),
                // Layout immagine con frecce
                Row(
                  children: [
                    // Freccia sinistra
                    if (mostraFrecciaSinistra)
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: AppColors.textColor1),
                        iconSize: 40,
                        onPressed: () {
                          String letteraPrecedente = String.fromCharCode(
                              currentLettera.codeUnitAt(0) - 1);
                          _cambiaLettera(letteraPrecedente, true);
                        },
                      )
                    else
                      SizedBox(
                          width: screenWidth * 0.04), // Placeholder per la freccia sinistra
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: _versoDestra
                                    ? const Offset(1.0, 0.0)
                                    : const Offset(-1.0, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            );
                          },
                          child: Container(
                            key: _immagineKey,
                            child: immagineCorrente != null
                                ? Image.asset(
                                    immagineCorrente!, // Percorso immagine
                                    width: 300,
                                    height: 300,
                                    fit: BoxFit.contain,
                                  )
                                : Text(
                                    "Immagine non trovata",
                                    style: GoogleFonts.roboto(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      foreground: Paint()
                                        ..shader = AppColors.textGradient
                                            .createShader(
                                          Rect.fromLTWH(0, 0, screenWidth, 0),
                                        ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    // Freccia destra
                    if (mostraFrecciaDestra)
                      IconButton(
                        icon: Icon(Icons.arrow_forward,
                            color: AppColors.textColor1),
                        iconSize: 40,
                        onPressed: () {
                          String letteraSuccessiva = String.fromCharCode(
                              currentLettera.codeUnitAt(0) + 1);
                          _cambiaLettera(letteraSuccessiva, false);
                        },
                      )
                    else
                      SizedBox(width: screenWidth * 0.04), // Placeholder per la freccia destra
                  ],
                ),
                SizedBox(height: screenHeight * 0.016),
                // Titolo "Lettera A"
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: _versoDestra
                            ? const Offset(1.0, 0.0)
                            : const Offset(-1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: Text(
                    'Lettera $currentLettera',
                    key: _letteraKey,
                    style: GoogleFonts.roboto(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = AppColors.textGradient.createShader(
                          Rect.fromLTWH(0, 0, screenWidth, 0),
                        ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                // Riquadro descrizione
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Container(
                    key: _testoKey,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
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
                ),
                SizedBox(height: screenHeight * 0.02),
                Spacer(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: IconButton(
                icon: CustomPaint(
                  size: Size(screenWidth * 0.045, screenHeight * 0.045),
                  painter: GradientIconPainter(
                    icon: Icons.arrow_back,
                    gradient: AppColors.textGradient,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ConsultazioneScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mappa per i testi delle lettere
  final Map<String, String> letterTexts = {
    'A':
        'Testo relativo alla lettera A. Da inserire procedura di riproduzione della lettera A. Per riprodurre la lettera A, chiudere la mano a pugno, estendere il pollice in avanti',
    'B':
        'Testo relativo alla lettera B. Da inserire procedura di riproduzione della lettera B. Per riprodurre la lettera B, tenere tutte le dita tese e unite tra loro e piegare il pollice in avanti sul palmo',
    'C':
        'Testo relativo alla lettera C. Da inserire procedura di riproduzione della lettera C. Per riprodurre la lettera C, aprire la mano formando una C. Quindi pollice e dita sono arcuate in modo da formare una C',
    'D':
        'Testo relativo alla lettera D. Da inserire procedura di riproduzione della lettera D. Per riprodurre la lettera D, tenere tutte le dita chiuse a pugno tranne l\'indice che è teso verso l\'alto',
    'E':
        'Testo relativo alla lettera E. Da inserire procedura di riproduzione della lettera E. Per riprodurre la lettera E, tenere tutte le dita piegate verso il palmo.',
    'F':
        'Testo relativo alla lettera F. Da inserire procedura di riproduzione della lettera F. Per riprodurre la lettera F, Forma un cerchio con il pollice e l\'indice, toccandoli tra loro. Le altre dita sono dritte e rivolte verso l\'alto.',
    'G':
        'Testo relativo alla lettera G. Da inserire procedura di riproduzione della lettera G. Per riprodurre la lettera G, Chiudi le dita ad eccezione dell\'indice e del pollice, che sono estesi orizzontalmente come se indicassero lateralmente.',
    'H':
        'Testo relativo alla lettera H. Da inserire procedura di riproduzione della lettera H. Per riprodurre la lettera H, Tieni il medio e l\'indice estesi e uniti, formando una "V" sdraiata. Piega le altre dita verso il palmo e tieni il pollice piegato sopra di esse.',
    'I':
        'Testo relativo alla lettera I. Da inserire procedura di riproduzione della lettera I. Per riprodurre la lettera I, Estendi solo il mignolo verso l\'alto, piegando tutte le altre dita verso il palmo e mantenendo il pollice appoggiato sulle dita.',
    'J':
        'Testo relativo alla lettera J. Da inserire procedura di riproduzione della lettera J. Per riprodurre la lettera J, Come per la lettera "I", estendi il mignolo. Poi usa il mignolo per tracciare nell\'aria una curva simile a una "J".',
    'K':
        'Testo relativo alla lettera K. Da inserire procedura di riproduzione della lettera K. Per riprodurre la lettera K, Tieni l\'indice e il medio aperti formando una "V". Piega il pollice verso il basso, appoggiandolo tra l\'indice e il medio. Piega le altre dita verso il palmo.',
    'L':
        'Testo relativo alla lettera L. Da inserire procedura di riproduzione della lettera L. Per riprodurre la lettera L, Forma una "L" con il pollice e l\'indice estesi, mentre le altre dita rimangono piegate verso il palmo.',
    'M':
        'Testo relativo alla lettera M. Da inserire procedura di riproduzione della lettera M. Per riprodurre la lettera M, Piega tutte le dita verso il palmo e posiziona il pollice sopra di esse. Assicurati che il pollice sia coperto da tre dita (indice, medio e anulare).',
    'N':
        'Testo relativo alla lettera N. Da inserire procedura di riproduzione della lettera N. Per riprodurre la lettera N, Simile alla "M", ma il pollice è coperto solo da due dita (indice e medio).',
    'O':
        'Testo relativo alla lettera O. Da inserire procedura di riproduzione della lettera O. Per riprodurre la lettera O, Forma un cerchio completo con tutte le dita, unendo i polpastrelli.',
    'P':
        'Testo relativo alla lettera P. Da inserire procedura di riproduzione della lettera P. Per riprodurre la lettera P, Come per la "K", ma con il palmo rivolto verso il basso.',
    'Q':
        'Testo relativo alla lettera Q. Da inserire procedura di riproduzione della lettera Q. Per riprodurre la lettera Q, Chiudi le dita e tieni il pollice e l\'indice estesi. Poi abbassa il pollice verso il basso come per indicare.',
    'R':
        'Testo relativo alla lettera R. Da inserire procedura di riproduzione della lettera R. Per riprodurre la lettera R, Incrocia l\'indice e il medio, mantenendo le altre dita piegate verso il palmo.',
    'S':
        'Testo relativo alla lettera S. Da inserire procedura di riproduzione della lettera S. Per riprodurre la lettera S, Forma un pugno chiuso con tutte le dita piegate verso il palmo, e il pollice che si appoggia sopra.',
    'T':
        'Testo relativo alla lettera T. Da inserire procedura di riproduzione della lettera T. Per riprodurre la lettera T, Forma un pugno e posiziona il pollice tra l\'indice e il medio.',
    'U':
        'Testo relativo alla lettera U. Da inserire procedura di riproduzione della lettera U. Per riprodurre la lettera U, Estendi l\'indice e il medio verso l\'alto, unendoli. Piega le altre dita verso il palmo e tieni il pollice piegato.',
    'V':
        'Testo relativo alla lettera V. Da inserire procedura di riproduzione della lettera V. Per riprodurre la lettera V, Estendi l\'indice e il medio verso l\'alto, tenendoli separati a formare una "V". Piega le altre dita verso il palmo.',
    'W':
        'Testo relativo alla lettera W. Da inserire procedura di riproduzione della lettera W. Per riprodurre la lettera W, Estendi il pollice, l\'indice e il medio verso l\'alto, formando una "W". Piega l\'anulare e il mignolo verso il palmo.',
    'X':
        'Testo relativo alla lettera X. Da inserire procedura di riproduzione della lettera X. Per riprodurre la lettera X, Piega l\'indice verso il palmo, formando una curva simile a un uncino. Piega le altre dita verso il palmo e tieni il pollice sopra.',
    'Y':
        'Testo relativo alla lettera Y. Da inserire procedura di riproduzione della lettera Y. Per riprodurre la lettera Y, Estendi il pollice e il mignolo in fuori, mentre pieghi le altre dita verso il palmo. La forma ricorda il simbolo del "telefono".',
    'Z':
        'Testo relativo alla lettera Z. Da inserire procedura di riproduzione della lettera Z. Per riprodurre la lettera Z, Usa l\'indice per tracciare una "Z" nell\'aria, mantenendo le altre dita piegate verso il palmo.',
  };

  // Mappa per le immagini dinamiche
  final Map<String, String> immaginiLettere = {
    'A': 'assets/lettere3d/letteraA.png',
    'B': 'assets/lettere3d/letteraB.png',
    'C': 'assets/lettere3d/letteraC.png',
    'D': 'assets/lettere3d/letteraD.png',
    'E': 'assets/lettere3d/letteraE.png',
    'F': 'assets/lettere3d/letteraF.png',
    'G': 'assets/lettere3d/letteraG.png',
    'H': 'assets/lettere3d/letteraH.png',
    'I': 'assets/lettere3d/letteraI.png',
    'J': 'assets/lettere3d/letteraJ.png',
    'K': 'assets/lettere3d/letteraK.png',
    'L': 'assets/lettere3d/letteraL.png',
    'M': 'assets/lettere3d/letteraM.png',
    'N': 'assets/lettere3d/letteraN.png',
    'O': 'assets/lettere3d/letteraO.png',
    'P': 'assets/lettere3d/letteraP.png',
    'Q': 'assets/lettere3d/letteraQ.png',
    'R': 'assets/lettere3d/letteraR.png',
    'S': 'assets/lettere3d/letteraS.png',
    'T': 'assets/lettere3d/letteraT.png',
    'U': 'assets/lettere3d/letteraU.png',
    'V': 'assets/lettere3d/letteraV.png',
    'W': 'assets/lettere3d/letteraW.png',
    'X': 'assets/lettere3d/letteraX.png',
    'Y': 'assets/lettere3d/letteraY.png',
    'Z': 'assets/lettere3d/letteraZ.png',
  };
}