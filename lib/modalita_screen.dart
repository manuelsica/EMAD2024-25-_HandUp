import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'game_screen_spelling.dart';
import 'app_colors.dart'; 

class ModalitaScreen extends StatefulWidget {
  const ModalitaScreen({Key? key}) : super(key: key);

  @override
  _ModalitaScreenState createState() => _ModalitaScreenState();
}

class _ModalitaScreenState extends State<ModalitaScreen> {
  // Funzione per recuperare le parole dal server
  Future<List<String>> fetchWords(String difficulty) async {
    const String apiUrl = "https://6d98-95-238-150-172.ngrok-free.app/generate-words"; // Sostituisci con l'indirizzo del tuo server
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"modalita": difficulty}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<String>.from(jsonResponse["words"]);
      } else {
        throw Exception("Errore nella risposta del server: ${response.body}");
      }
    } catch (e) {
      print("Errore: $e");
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
                const SizedBox(height: 30), // Manteniamo lo spazio aggiuntivo se necessario
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
                const SizedBox(width: 10),
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
