import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'app_colors.dart';
import 'top_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'backend_config.dart';
import 'game_screen_spelling.dart';
import "hangman_screen.dart";

class DifficultySelectionScreen extends StatefulWidget {
  final String gameMode;

  const DifficultySelectionScreen({Key? key, required this.gameMode}) : super(key: key);

  @override
  _DifficultySelectionScreenState createState() =>
      _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = 'Username';
  int points = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? usernameFromStorage = await storage.read(key: 'username');
    String? pointsStr = await storage.read(key: 'points');
    int pointsFromStorage = 0;
    if (pointsStr != null) {
      pointsFromStorage = int.tryParse(pointsStr) ?? 0;
    }

    setState(() {
      username = usernameFromStorage ?? 'Username';
      points = pointsFromStorage;
      isLoading = false;
    });
  }

  Future<List<String>> fetchWords(String difficulty) async {
    final String apiUrl = BackendConfig.wordsGenerationUrl;

    try {
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        throw Exception(
            "Token di autenticazione mancante. Effettua il login di nuovo.");
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
          throw Exception(
              "Autenticazione fallita. Effettua il login di nuovo.");
        } else {
          throw Exception("Errore nella risposta del server: ${response.body}");
        }
      }
    } catch (e) {
      print("Errore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return [];
    }
  }

  void navigateToGameScreen(BuildContext context, String difficulty) async {
    final words = await fetchWords(difficulty);

    if (words.isNotEmpty) {
      if (widget.gameMode == "spelling"){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(words: words),
          ),
        );
      } else if (widget.gameMode == "hangman"){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HangmanGameScreen(words: words),
          ),
        );
      }
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => GameScreen(words: words),
      //   ),
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nel caricamento delle parole")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        // Rimosso il drawer: SideMenu(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // Rimosso il drawer: SideMenu(),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  TopBar(
                    username: username,
                    points: points,
                    showMenu: false, // Imposta showMenu su false per nascondere il menu
                    showUser: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Container informativo
                            Container(
                              width: double.infinity,
                              height: screenHeight * 0.25,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.transparent,
                                border: Border.all(
                                  color: AppColors.textColor2,
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppColors.gradientText(
                                        "Seleziona la\nDifficoltà",
                                        screenWidth * 0.08,
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    right: -45,
                                    bottom: -50,
                                    child: Image.asset(
                                      'assets/difficulty.png',
                                      width: screenWidth * 0.6,
                                      height: screenWidth * 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.06),
                            DifficultyButton(
                              title: "Facile",
                              screenWidth: screenWidth,
                              difficulty: "facile",
                              onPressed: () =>
                                  navigateToGameScreen(context, "facile"),
                            ),
                            SizedBox(height: screenHeight * 0.04),
                            DifficultyButton(
                              title: "Medio",
                              screenWidth: screenWidth,
                              difficulty: "medio",
                              onPressed: () =>
                                  navigateToGameScreen(context, "medio"),
                            ),
                            SizedBox(height: screenHeight * 0.04),
                            DifficultyButton(
                              title: "Difficile",
                              screenWidth: screenWidth,
                              difficulty: "difficile",
                              onPressed: () =>
                                  navigateToGameScreen(context, "difficile"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // **Spostato il bottone back arrow all'angolo in alto a sinistra**
              Align(
                alignment: Alignment.topLeft,
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
                      Navigator.pop(context);
                      // Se preferisci tornare a Home direttamente, puoi usare:
                      // Navigator.pushReplacement(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const Home()),
                      // );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Classe per bottone con animazione
class DifficultyButton extends StatefulWidget {
  final String title;
  final double screenWidth;
  final String difficulty;
  final VoidCallback onPressed;

  const DifficultyButton({
    Key? key,
    required this.title,
    required this.screenWidth,
    required this.difficulty,
    required this.onPressed,
  }) : super(key: key);

  @override
  _DifficultyButtonState createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<DifficultyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.containerOpaqueColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: AppColors.gradientText(
              widget.title,
              widget.screenWidth * 0.08,
            ),
          ),
        ),
      ),
    );
  }
}