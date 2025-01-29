// lib/sidemenu.dart
import "package:flutter/material.dart";
import "consultazione.dart";
import "app_colors.dart";
import "multiplayer_home.dart";
import "classifiche.dart";
import "home.dart";
import 'login.dart';
import 'registration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "shop_screen.dart";
import "selezione_gioco.dart";
import "difficulty_selection.dart";
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'backend_config.dart';
import "math_game_screen.dart";
import "hangman_screen.dart";
import "scarabeo_screen.dart";

class SideMenu extends StatefulWidget {
  SideMenu({Key? key}) : super(key: key);

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  final storage = FlutterSecureStorage();
  String _username = 'Username'; // Valore di default
  int _points = 0; // Valore di default
  bool _isLoggedIn = false; // Variabile per gestire lo stato di login

  final String logoutUrl = BackendConfig.baseUrl + 'logout';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? token = await storage.read(key: 'access_token');
    String? username = await storage.read(key: 'username');
    String? pointsStr = await storage.read(key: 'points');

    if (token != null && username != null && pointsStr != null) {
      int? points = int.tryParse(pointsStr);
      setState(() {
        _isLoggedIn = true;
        _username = username;
        _points = points ?? 0;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _username = 'Username';
        _points = 0;
      });
    }
  }

  /// Funzione per effettuare il logout lato server
  Future<bool> _logoutServer(String token) async {
    final url = Uri.parse(logoutUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Errore nel logout server: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Eccezione durante il logout server: $e');
      return false;
    }
  }

  /// Funzione di logout che gestisce sia il lato client che il lato server
  Future<void> _logout(BuildContext context) async {
    String? token = await storage.read(key: 'access_token');
    if (token != null) {
      final logoutSuccess = await _logoutServer(token);
      if (logoutSuccess) {
        await storage.delete(key: 'access_token');
        await storage.delete(key: 'username');
        await storage.delete(key: 'points');
        setState(() {
          _isLoggedIn = false;
          _username = 'Username';
          _points = 0;
        });
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LandingPageScreen()), // Reindirizza a LandingPageScreen
          (Route<dynamic> route) => false, // Rimuove tutte le schermate precedenti
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante il logout. Riprova.')),
        );
      }
    } else {
      // Se non c'è un token, naviga comunque verso LandingPageScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPageScreen()), // Reindirizza a LandingPageScreen
        (Route<dynamic> route) => false, // Rimuove tutte le schermate precedenti
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900.withOpacity(0.8),
              Colors.purple.shade800.withOpacity(0.8),
            ],
          ),
        ),
        child: _isLoggedIn ? _buildLoggedInMenu(context) : _buildLoggedOutMenu(context),
      ),
    );
  }

  Widget _buildLoggedInMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<String> questions = ["x", "y"];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header della sidebar con icona utente, username e punti
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.purple.shade800.withOpacity(0.5),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    _username,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    'punti: $_points',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
              // Icona per il logout
              Positioned(
                top: 0,
                right: -10,
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _logout(context),
                ),
              ),
            ],
          ),
        ),
        // Menu a tendina "Singleplayer"
        ExpansionTile(
          leading: const Icon(Icons.gamepad, color: Colors.white), // Icona valida per Singleplayer
          title: const Text('Singleplayer', style: TextStyle(color: Colors.white)),
          children: [
             // Aggiunta del pulsante "Home"
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const GameSelectionScreen()), // Naviga a selezione_gioco.dart
                  (Route<dynamic> route) => false, // Rimuove tutte le schermate precedenti
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_mark, color: Colors.white),
              title: const Text('Impiccato', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DifficultySelectionScreen(gameMode: "hangman"), // Naviga a selezione_gioco.dart
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: Colors.white), // Icona per Giochi Matematici
              title: const Text('Giochi Matematici', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MathGameScreen(questions: ["2 + 3 = ", "3 + 5 = "]), // Naviga a selezione_gioco.dart
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.spellcheck, color: Colors.white), // Icona per Spelling
              title: const Text('Spelling', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Home(), // Naviga a Home.dart
                  ),
                );
              },
            ),
          ],
        ),
        // Pulsante per accedere alla modalità multiplayer
        ListTile(
          leading: const Icon(Icons.sports_esports, color: Colors.white),
          title: const Text('MultiPlayer', style: TextStyle(color: Colors.white)),
          onTap: () async {
            final token = await storage.read(key: 'access_token');
            if (token != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MultiplayerHome()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Devi effettuare il login per accedere a Multiplayer')),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LandingPageScreen()), // Reindirizza a LandingPageScreen
                (Route<dynamic> route) => false,
              );
            }
          },
        ),
        // Pulsante per accedere alle classifiche
        ListTile(
          leading: const Icon(Icons.star, color: Colors.white),
          title: const Text('Classifiche', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
            );
          },
        ),
        // Pulsante per accedere allo shop
        ListTile(
          leading: const Icon(Icons.store, color: Colors.white),
          title: const Text('Shop', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ShopScreen()),
            );
          },
        ),
        // Pulsante per accedere alla pagina di consultazione
        ListTile(
          leading: const Icon(Icons.menu_book, color: Colors.white),
          title: const Text('Consultazione', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Consultazione()),
            );
          },
        ),
        // Pulsante per accedere alla pagina delle impostazioni
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.white),
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ScarabeoGameScreen(playerName: "test", opponentName: "test1")),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoggedOutMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header della sidebar con icona generica
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.purple.shade800.withOpacity(0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple,
                child: Icon(Icons.person_outline, size: 35, color: Colors.white),
              ),
              SizedBox(height: screenHeight * 0.01),
              const Text(
                'Benvenuto',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
        // Pulsante di Login
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple, // Colore del pulsante
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        // Pulsante di Registrazione
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700, // Colore del pulsante
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/registration');
            },
            child: const Text(
              'Registrati',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}