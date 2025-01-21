// lib/consultazione.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'sidemenu.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consultazione_lettera.dart';
import 'top_bar.dart';
import 'socket_service.dart';
import 'user.dart';
import "animated_button.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const Consultazione());
  });
}

class Consultazione extends StatelessWidget {
  const Consultazione({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Rimuove il banner di debug
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const ConsultazioneScreen(),
    );
  }
}

class ConsultazioneScreen extends StatefulWidget {
  const ConsultazioneScreen({Key? key}) : super(key: key);

  @override
  _ConsultazioneScreenState createState() => _ConsultazioneScreenState();
}

class _ConsultazioneScreenState extends State<ConsultazioneScreen>
    with SingleTickerProviderStateMixin {
  final SocketService socketService = SocketService();
  final FlutterSecureStorage storage = const FlutterSecureStorage(); // Inizializza FlutterSecureStorage
  String username = "USERNAME"; // Questo valore verrà aggiornato dinamicamente
  int yourPoints = 0; // Questo valore verrà aggiornato dinamicamente
  bool isLoading = true;

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isContainerVisible = false;
  String _lobbyType = 'Spelling';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    socketService.connect(); // Assicurati che la connessione sia stabilita
    _initializeUserData(); // Inizializza i dati utente
  }

  @override
  void dispose() {
    _controller.dispose();
    socketService.disconnect(); // Disconnette il socket
    super.dispose();
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
    final data = await socketService.fetchLeaderboard(); // Usa fetchLeaderboard o un endpoint appropriato
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

  void _toggleContainer() {
    setState(() {
      _isContainerVisible = !_isContainerVisible;
      if (_isContainerVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        drawer: SideMenu(),
        body: Stack(
          children: [
            Container(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AppColors.gradientText(
                                          'Libreria di Consultazione',
                                          screenWidth * 0.06
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
                                              borderRadius:
                                                  BorderRadius.circular(30),
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
                                      String lettera = String.fromCharCode(65 + index); // 65 è il codice ASCII di 'A'
                                      return AnimatedButton(
                                        onPressed: () {},
                                        isLocked: false,
                                        child: _buildLobbyItem(
                                          lettera: lettera,
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          context:
                                              context, // Passa il contesto per la navigazione
                                        ),
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
          ],
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
                      color: AppColors.textColor1, // Colore specificato nel TextStyle
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
                      color: AppColors.textColor3, // Colore specificato nel TextStyle
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