import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Importa Provider
import 'dart:io';
import 'package:provider/provider.dart';
import 'sidemenu.dart';
import 'game_screen_spelling.dart';
import 'app_colors.dart';
import 'modalita_screen.dart';
import 'socket_service.dart'; // Importa SocketService
import 'package:google_fonts/google_fonts.dart';
import 'top_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Importa FlutterSecureStorage

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = 'Username';
  int points = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawer: SideMenu(),
        body: Consumer<SocketService>(
          builder: (context, socketService, child) {
            // Mostra un indicatore di caricamento mentre i dati vengono caricati
            if (isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            // App Bar con dati dinamici
                            TopBar(
                              username: username,
                              points: points,
                              showMenu: true,
                              showUser: true,
                            ),
                            // Contenuto Principale
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  // Top Card
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(20, 20, 60, 30),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border.all(
                                          color: AppColors.textColor2, width: 2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Icona
                                        Positioned(
                                          right: -MediaQuery.of(context).size.width * 0.57,
                                          bottom: -MediaQuery.of(context).size.height * 0.66,
                                          child: Image.asset(
                                            'assets/hand_icon.png',
                                            width: MediaQuery.of(context).size.width * 1.5,
                                            height: MediaQuery.of(context).size.height * 1.5,
                                          ),
                                        ),
                                        // Titolo e Descrizione
                                        Padding(
                                          padding: const EdgeInsets.only(right: 0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              AppColors.gradientText(
                                                  "Allenati con parole casuali",
                                                  MediaQuery.of(context).size.width * 0.07),
                                              const SizedBox(height: 0),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(right: 80),
                                                child: Column(
                                                  children: [
                                                    // Descrizione
                                                    Text(
                                                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita a posuere purus egestas.',
                                                      style: TextStyle(
                                                          color: Colors.grey[300]),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(30),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.pink
                                                                  .withOpacity(0.8),
                                                              blurRadius: 20,
                                                              spreadRadius: 4,
                                                              offset:
                                                                  const Offset(0, 0),
                                                            ),
                                                          ],
                                                        ),
                                                        // Bottone per iniziare il gioco
                                                        child: ElevatedButton(
                                                            // Effetto Neon
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.pink,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 15,
                                                                vertical: 5,
                                                              ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(30),
                                                              ),
                                                              elevation: 0,
                                                              shadowColor:
                                                                  Colors.transparent,
                                                            ),
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        const ModalitaScreen()),
                                                              );
                                                            },
                                                            child: const Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                  horizontal: 15,
                                                                  vertical: 8,
                                                                ),
                                                                child: Text(
                                                                  'Parole casuali',
                                                                ))),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Menu Items
                                  _buildMenuItem(
                                    title: 'Casa',
                                    imageUrl: 'assets/house_icon.png',
                                    isLocked: false,
                                    screenWidth: MediaQuery.of(context).size.width,
                                    screenHeight: MediaQuery.of(context).size.height,
                                  ),
                                  _buildMenuItem(
                                    title: 'Animali',
                                    imageUrl: 'assets/animal_icon.png',
                                    isLocked: true,
                                    points: 350,
                                    screenWidth: MediaQuery.of(context).size.width,
                                    screenHeight: MediaQuery.of(context).size.height,
                                  ),
                                  _buildMenuItem(
                                    title: 'Cibi',
                                    imageUrl: 'assets/food_icon.png',
                                    isLocked: true,
                                    points: 350,
                                    screenWidth: MediaQuery.of(context).size.width,
                                    screenHeight: MediaQuery.of(context).size.height,
                                  ),
                                  _buildMenuItem(
                                    title: 'Svago',
                                    imageUrl: 'assets/tv_icon.png',
                                    isLocked: true,
                                    points: 350,
                                    screenWidth: MediaQuery.of(context).size.width,
                                    screenHeight: MediaQuery.of(context).size.height,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Funzione per creare gli altri play modes
  Widget _buildMenuItem({
    required String title,
    required String imageUrl,
    bool isLocked = false,
    int points = 0,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.containerOpaqueColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icona del Mode
          Positioned(
            left: -screenWidth * 0.04,
            top: -screenHeight * 0.11,
            child: Image.asset(
              imageUrl,
              width: screenWidth * 0.28,
              height: screenHeight * 0.28,
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(100, 10, 20, 10),
            title: AppColors.gradientText(title, screenWidth * 0.048),
            trailing: isLocked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: Size(screenWidth * 0.04, screenWidth * 0.04),
                        painter: GradientIconPainter(
                          icon: Icons.person,
                          gradient: AppColors.textGradient,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Costo: $points punti',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : null,
            onTap: () {
              if (isLocked) {
                // Mostra un messaggio o gestisci il comportamento per le modalità bloccate
              } else {
                // Naviga alla modalità di gioco
              }
            },
          ),
        ],
      ),
    );
  }
}