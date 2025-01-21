// lib/classifiche.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sidemenu.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'top_bar.dart';
import 'socket_service.dart';
import 'user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Importa FlutterSecureStorage

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const LeaderboardScreen());
  });
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Rimuove il banner di debug
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LeaderboardHomeScreen(),
    );
  }
}

class LeaderboardHomeScreen extends StatefulWidget {
  const LeaderboardHomeScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardHomeScreenState createState() => _LeaderboardHomeScreenState();
}

class _LeaderboardHomeScreenState extends State<LeaderboardHomeScreen> {
  final SocketService socketService = SocketService();
  final FlutterSecureStorage storage = const FlutterSecureStorage(); // Inizializza FlutterSecureStorage
  List<User> topUsers = [];
  int? yourRank;
  int? yourPoints;
  bool isLoading = true;
  String username = "USERNAME"; // Questo valore verrà aggiornato dal server o dalla storage

  @override
  void initState() {
    super.initState();
    socketService.connect(); // Assicurati che la connessione sia stabilita
    _initializeUserData(); // Inizializza i dati utente
  }

  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }

  /// Inizializza i dati dell'utente recuperando l'username dalla storage
  Future<void> _initializeUserData() async {
    try {
      // Recupera l'username dalla memorizzazione locale
      String? storedUsername = await storage.read(key: 'username');
      int? storedPoints = await storage.read(key: 'points').then((value) => value != null ? int.tryParse(value) : null);

      setState(() {
        username = storedUsername ?? "USERNAME";
        yourPoints = storedPoints ?? 0;
      });

      // Successivamente, recupera la classifica dal server
      await fetchLeaderboard(); // Attendi che la classifica venga recuperata
    } catch (e) {
      print('Errore in _initializeUserData: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nell\'inizializzazione dei dati utente.')),
      );
    }
  }

  Future<void> fetchLeaderboard() async {
    try {
      print('Inizio fetchLeaderboard');
      final data = await socketService.fetchLeaderboard();
      if (data != null) {
        setState(() {
          topUsers = (data['leaderboard'] as List)
              .map((json) => User.fromJson(json))
              .toList();
          yourRank = data['your_rank'] as int?;
          yourPoints = data['your_points'] as int? ?? yourPoints; // Usa i punti dalla classifica se disponibili
          // Se il server fornisce l'username, aggiorna l'username
          if (data['your_username'] != null && data['your_username'].toString().isNotEmpty) {
            username = data['your_username'];
          }
          isLoading = false;
        });
        print('Classifica caricata con successo.');
      } else {
        setState(() {
          isLoading = false;
        });
        // Opzionale: Mostra un messaggio di errore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel recupero della classifica. Riprova più tardi.')),
        );
        print('Errore nel recupero della classifica: Dati null.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nel recupero della classifica. Riprova più tardi.')),
      );
      print('Eccezione durante fetchLeaderboard: $e');
    }
  }

  // Costruisce un singolo elemento della classifica
  Widget _buildLeaderboardItem({
    required String position,
    required String username,
    required String points,
    required String avatar,
    required double screenWidth,
    required double screenHeight,
    bool isFirst = false,
    bool isSecond = false,
    bool isThird = false,
  }) {
    double avatarSize = screenWidth * 0.12;
    if (isFirst) {
      avatarSize = screenWidth * 0.18;
    } else if (isSecond) {
      avatarSize = screenWidth * 0.15;
    } else if (isThird) {
      avatarSize = screenWidth * 0.13;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: avatarSize + 40,
          margin: EdgeInsets.only(top: avatarSize / 2, bottom: 0),
          padding: EdgeInsets.only(top: 16, bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.purple.shade900.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              SizedBox(width: (avatarSize + 16)),
              // Visualizzazione posizione
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: isFirst ? 12 : 10),
                      child: Row(
                        children: [
                          isFirst
                              ? AppColors.firstPlaceGradientText(
                                  '$position° Posto',
                                  isFirst
                                      ? screenWidth * 0.1
                                      : screenWidth * 0.07)
                              : AppColors.gradientText(
                                  '$position° Posto',
                                  isFirst
                                      ? screenWidth * 0.1
                                      : screenWidth * 0.07)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Visualizzazione punti
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: isFirst ? screenHeight * 0.035 : isSecond ? screenHeight * 0.025 : screenHeight * 0.017),
                  AppColors.gradientText(
                      "Punti: $points", screenWidth * 0.035),
                ],
              ),
            ],
          ),
        ),
        // Display Avatar
        Positioned(
          top: isFirst ? 55 : 45,
          left: -5,
          child: CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: Colors.purple,
            child: Text(
              avatar,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: avatarSize * 0.5,
              ),
            ),
          ),
        ),
        // Display Username
        Positioned(
          top: avatarSize / 2 - 11,
          left: isFirst ? avatarSize + 5 : avatarSize + 15,
          child: Text(
            username,
            style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.white.withOpacity(1.0),
                    offset: Offset(0, 0),
                  ),
                  Shadow(
                    blurRadius: 20,
                    color: Colors.white.withOpacity(0.8),
                    offset: Offset(0, 0),
                  ),
                  Shadow(
                    blurRadius: 30,
                    color: Colors.white.withOpacity(0.5),
                    offset: Offset(0, 0),
                  ),
                ]),
          ),
        ),
      ],
    );
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
              // App Bar
              TopBar(
                  username: username,
                  points: yourPoints ?? 0,
                  showMenu: true,
                  showUser: true),
              // Current User Position
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Text(
                            yourRank != null ? '$yourRank' : 'N/A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 36,
                      child: AppColors.gradientText(
                          "Sei in posizione:", screenWidth * 0.06),
                    ),
                  ],
                ),

              // Leaderboard Title
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: AppColors.gradientText(
                      "Classifica Generale:", screenWidth * 0.07),
                ),
              ),

              // Leaderboard List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchLeaderboard,
                  child: topUsers.isEmpty
                      ? ListView(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "Nessun utente trovato nella classifica.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.05,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: topUsers.length,
                          itemBuilder: (context, index) {
                            final user = topUsers[index];
                            bool isFirst = index == 0;
                            bool isSecond = index == 1;
                            bool isThird = index == 2;
                            return _buildLeaderboardItem(
                              position: '${index + 1}',
                              username: user.username,
                              points: '${user.points}',
                              avatar: user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'U',
                              screenWidth: screenWidth,
                              isFirst: isFirst,
                              isSecond: isSecond,
                              isThird: isThird,
                              screenHeight: screenHeight,
                            );
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
