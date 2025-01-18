// lib/select_multiplayer.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'spelling.dart'; 
import 'app_colors.dart';
import 'backend_config.dart';
import 'socket_service.dart'; 

class ModalitaScreen extends StatefulWidget {
  // Ricevi la lobbyId, così sai a quale lobby appartieni
  final String lobbyId;

  const ModalitaScreen({Key? key, required this.lobbyId}) : super(key: key);

  @override
  _ModalitaScreenState createState() => _ModalitaScreenState();
}

class _ModalitaScreenState extends State<ModalitaScreen> {
  final storage = const FlutterSecureStorage();

  late SocketService socketService;
  bool _hasVoted = false;       // Per evitare doppi voti
  bool _waitingResult = false;  // Per mostrare un eventuale caricamento
  String? _finalMode;           // La modalità vincente (se già disponibile)
  
  // Stato per i conteggi dei voti
  Map<String, int> _voteCounts = {
    "facile": 0,
    "medio": 0,
    "difficile": 0,
  };

  @override
  void initState() {
    super.initState();
    socketService = Provider.of<SocketService>(context, listen: false);

    // Ascolta l'evento "vote_result"
    socketService.voteResultStream.listen((modeChosen) async {
      // Arriva la modalità definitiva scelta
      setState(() {
        _finalMode = modeChosen;
        _waitingResult = false;
      });
      // Una volta che sappiamo la "modeChosen", prendiamo le parole e navighiamo
      _navigateToGameScreen(modeChosen);
    });

    // Ascolta l'evento "vote_update" per aggiornare i conteggi dei voti
    socketService.voteUpdateStream.listen((voteCounts) {
      setState(() {
        _voteCounts = Map<String, int>.from(voteCounts);
      });
    });
  }

  // --- FUNZIONE DI FETCH PAROLE ---
  Future<List<String>> fetchWords(String difficulty) async {
    final String apiUrl = BackendConfig.wordsGenerationUrl;
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        throw Exception("Token di autenticazione mancante. Effettua il login di nuovo.");
      }
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"modalita": difficulty}),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<String>.from(jsonResponse["words"]);
      } else {
        if (response.statusCode == 401) {
          throw Exception("Autenticazione fallita. Effettua il login di nuovo.");
        } else {
          throw Exception("Errore nella risposta del server: ${response.body}");
        }
      }
    } catch (e) {
      print("Errore: $e");
      return [];
    }
  }

  // --- INVIO VOTO ---
  void _voteMode(String difficulty) {
    if (_hasVoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hai già votato una modalità.")),
      );
      return;
    }
    setState(() {
      _hasVoted = true;
      _waitingResult = true;
    });
    // Manda l'evento al server
    socketService.voteForMode(widget.lobbyId, difficulty);
  }

  // --- NAVIGA ALLA SCHERMATA DI GIOCO (usando le parole) ---
  Future<void> _navigateToGameScreen(String difficulty) async {
    final words = await fetchWords(difficulty);
    if (!mounted) return; // Evita errori se il widget è stato smontato

    if (words.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreenSpelling(
            words: words,
            lobbyId: widget.lobbyId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nel caricamento delle parole")),
      );
    }
  }

  // --- Widget personalizzato per i bottoni con gradiente e animazioni ---
  Widget buildGradientButton(BuildContext context, String label, String difficulty, IconData iconData) {
    // Recupera il numero di voti per questa modalità
    int voteCount = _voteCounts[difficulty] ?? 0;

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GradientButton(
        label: label,
        difficulty: difficulty,
        iconData: iconData,
        voteCount: voteCount, // Passa il numero di voti al bottone
        onPressed: () => _voteMode(difficulty), // Invoca la funzione di voto
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: AppColors.gradientText(
          "Vota Difficoltà", // Titolo aggiornato
          26.0,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(context, "Facile", "facile", Icons.sentiment_very_satisfied),
                buildGradientButton(context, "Medio", "medio", Icons.sentiment_satisfied),
                buildGradientButton(context, "Difficile", "difficile", Icons.sentiment_dissatisfied),
                SizedBox(height: screenHeight * 0.03),
                if (_waitingResult) 
                  SpinPerfect(
                    animate: true,
                    duration: const Duration(seconds: 2),
                    infinite: true,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                if (_finalMode != null)
                  FadeIn(
                    duration: const Duration(milliseconds: 800),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Modalità scelta: $_finalMode",
                        style: const TextStyle(color: Colors.white, fontSize: 18),
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
}

/// WIDGET PERSONALIZZATO PER L'ANIMAZIONE DEL BOTTONE CON GRADIENTE E VOTI
class GradientButton extends StatefulWidget {
  final String label;
  final String difficulty;
  final IconData iconData;
  final int voteCount; // Nuovo parametro per i conteggi dei voti
  final VoidCallback onPressed;

  const GradientButton({
    Key? key,
    required this.label,
    required this.difficulty,
    required this.iconData,
    required this.voteCount, // Inizializzato nel costruttore
    required this.onPressed,
  }) : super(key: key);

  @override
  _GradientButtonState createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {
          _scale = 1 - _controller.value;
        });
      });

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Transform.scale(
      scale: _scale,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
          decoration: BoxDecoration(
            gradient: AppColors.containerBorderGradient,
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.containerOpaqueColor,
              padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Row(
                key: ValueKey<int>(widget.voteCount),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.iconData,
                    color: Colors.white,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  AppColors.gradientText(
                    widget.label,
                    20.0,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  // Visualizza il conteggio dei voti con animazione
                  FadeIn(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      "(${widget.voteCount})",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
