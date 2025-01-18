// lib/modalita_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Importa FlutterSecureStorage
import 'game_screen_spelling.dart';
import 'app_colors.dart';
import "backend_config.dart"; 

class ModalitaScreen extends StatefulWidget {
  const ModalitaScreen({Key? key}) : super(key: key);

  @override
  _ModalitaScreenState createState() => _ModalitaScreenState();
}

class _ModalitaScreenState extends State<ModalitaScreen> {
  final storage = const FlutterSecureStorage(); // Inizializza FlutterSecureStorage

  // Funzione per recuperare le parole dal server
  Future<List<String>> fetchWords(String difficulty) async {
    final String apiUrl = BackendConfig.wordsGenerationUrl; // Utilizza l'URL dal backend_config.dart

    try {
      // Leggi il token JWT salvato
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        // Se il token non è presente, mostra un messaggio di errore
        throw Exception("Token di autenticazione mancante. Effettua il login di nuovo.");
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Aggiungi il token nell'header Authorization
        },
        body: jsonEncode({"modalita": difficulty}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<String>.from(jsonResponse["words"]);
      } else {
        // Gestisci errori specifici in base allo status code
        if (response.statusCode == 401) {
          throw Exception("Autenticazione fallita. Effettua il login di nuovo.");
        } else {
          throw Exception("Errore nella risposta del server: ${response.body}");
        }
      }
    } catch (e) {
      print("Errore: $e");
      // Puoi anche mostrare un messaggio all'utente se necessario
      return [];
    }
  }

  // Funzione per navigare verso la schermata di gioco
  void navigateToGameScreen(BuildContext context, String difficulty) async {
    final words = await fetchWords(difficulty);

    if (words.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(words: words),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nel caricamento delle parole")),
      );
    }
  }

  // Widget personalizzato per i bottoni con gradiente, icona e animazione
  Widget buildGradientButton(BuildContext context, String label, String difficulty, IconData iconData) {
    return GradientButton(
      label: label,
      difficulty: difficulty,
      iconData: iconData,
      onPressed: () => navigateToGameScreen(context, difficulty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Sfondo della schermata
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor, // Sfondo AppBar
        elevation: 0, // Rimuove l'ombra AppBar
        centerTitle: true, // Centra il titolo
        title: AppColors.gradientText(
          "Seleziona Modalità", // Titolo con gradiente
          26.0,
        ),
      ),
      body: Center(
        child: SingleChildScrollView( // Permette lo scrolling se necessario
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(context, "Facile", "facile", Icons.sentiment_very_satisfied),
                buildGradientButton(context, "Medio", "medio", Icons.sentiment_satisfied),
                buildGradientButton(context, "Difficile", "difficile", Icons.sentiment_dissatisfied),
                SizedBox(height: screenHeight * 0.03), // Manteniamo lo spazio aggiuntivo se necessario
                // Logo rimosso
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget personalizzato per gestire l'animazione del bottone
class GradientButton extends StatefulWidget {
  final String label;
  final String difficulty;
  final IconData iconData;
  final VoidCallback onPressed;

  const GradientButton({
    Key? key,
    required this.label,
    required this.difficulty,
    required this.iconData,
    required this.onPressed,
  }) : super(key: key);

  @override
  _GradientButtonState createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;

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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
        decoration: BoxDecoration(
          gradient: AppColors.containerBorderGradient, // Gradiente per il bordo
          borderRadius: BorderRadius.circular(30.0), // Bordi arrotondati
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3), // Ombra sottostante
            ),
          ],
        ),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.containerOpaqueColor, // Sfondo del bottone
              padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0), // Bordo arrotondato
              ),
              elevation: 0, // Rimuove l'elevazione predefinita
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.iconData,
                  color: Colors.white,
                ),
                SizedBox(width: screenWidth * 0.01),
                AppColors.gradientText(
                  widget.label,
                  20.0, // Dimensione del testo
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}