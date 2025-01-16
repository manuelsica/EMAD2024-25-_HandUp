import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "sidemenu.dart";
import "app_colors.dart";
import "top_bar.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 

class ShopScreen extends StatefulWidget { 
  const ShopScreen({Key? key}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        drawer: SideMenu(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: SideMenu(),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // TopBar con username e punti
              TopBar(
                username: username, // Usa l'username dinamico
                points: points,     // Usa i punti dinamici
                showMenu: true,
                showUser: true,
              ),

              // Contenuto principale
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card dei punti con carrello
                        _buildPointsCard(screenWidth),

                        SizedBox(height: screenHeight * 0.03),

                        // Titolo sezione sbloccabili
                        AppColors.gradientText(
                          "Sbloccabili:",
                          screenWidth * 0.06,
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Lista degli elementi sbloccabili
                        _buildUnlockableItem(
                          context: context,
                          title: "Scarabeo",
                          icon: "assets/scarabeo.png",
                          points: 120,
                          screenWidth: screenWidth,
                        ),

                        _buildUnlockableItem(
                          context: context,
                          title: "Impiccato",
                          icon: "assets/impiccato.png",
                          points: 120,
                          screenWidth: screenWidth,
                        ),

                        _buildUnlockableItem(
                          context: context,
                          title: "Giochi\nMatematici",
                          icon: "assets/matematica.png",
                          points: 120,
                          screenWidth: screenWidth,
                        ),

                        // Elemento rimuovi pubblicità
                        _buildRemoveAdsItem(screenWidth),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(double screenWidth) {
    return Container(
      width: double.infinity,
      height: 150, // Fixed height for consistency
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900.withOpacity(0.3),
            Colors.purple.shade800.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.textColor1.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppColors.gradientText(
                "Punti:",
                screenWidth * 0.06,
              ),
              Text(
                "$points",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Positioned(
            right: -60,
            bottom: -80,
            child: Image.asset(
              'assets/carrello.png',
              width: screenWidth * 0.6,
              height: screenWidth * 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockableItem({
    required BuildContext context,
    required String title,
    required String icon,
    required int points,
    required double screenWidth,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      height: 90, // Fixed height for consistency
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.textColor1.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(width: screenWidth * 0.12),
                  SizedBox(width: screenWidth * 0.04),
                  // Titolo del gioco
                  AppColors.gradientText(
                    title,
                    screenWidth * 0.045,
                  ),
                ],
              ),
              // Punti necessari
              Row(
                children: [
                  Text(
                    "Punti necessari:",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "$points",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: -60,
            top: -60,
            child: Image.asset(
              icon,
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveAdsItem(double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      height: 90, // Fixed height for consistency
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.textColor1.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(width: screenWidth * 0.12),
                  SizedBox(width: screenWidth * 0.04),
                  // Testo rimuovi pubblicità
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppColors.gradientText(
                        "Sblocco",
                        screenWidth * 0.045,
                      ),
                      AppColors.gradientText(
                        "Pubblicità",
                        screenWidth * 0.045,
                      ),
                    ],
                  ),
                ],
              ),
              // Prezzo
              Text(
                "4.99\$",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Positioned(
            left: -40,
            top: -30,
            child: Image.asset(
              'assets/ads.png',
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
            ),
          ),
        ],
      ),
    );
  }
}