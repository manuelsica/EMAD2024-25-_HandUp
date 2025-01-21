import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "sidemenu.dart";
import "app_colors.dart";
import "top_bar.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "home.dart";
import "animated_button.dart";


class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({Key? key}) : super(key: key);

  @override
  _GameSelectionScreenState createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
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
              TopBar(
                username: username,
                points: points,
                showMenu: true,
                showUser: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    "Seleziona la\nModalità di\ngioco",
                                    screenWidth * 0.08,
                                  ),
                                ],
                              ),
                              Positioned(
                                right: -80,
                                bottom: -120,
                                child: Image.asset(
                                  'assets/playing_hand.png',
                                  width: screenWidth * 0.8,
                                  height: screenWidth * 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        AnimatedButton(
                          isLocked: true,
                          onPressed: () {},
                          child: _buildGameModeCard(
                            context: context,
                            title: "Impiccato",
                            icon: "assets/impiccato.png",
                            isLocked: true,
                            screenWidth: screenWidth,
                            gameScreen: Home(),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.016),
                        AnimatedButton(
                          onPressed: () {},
                          isLocked: true,
                          child: _buildGameModeCard(
                            context: context,
                            title: "Giochi\nMatematici",
                            icon: "assets/matematica.png",
                            isLocked: true,
                            screenWidth: screenWidth,
                            gameScreen: Home(),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.016),
                        AnimatedButton(
                          onPressed: () {},
                          isLocked: false,
                          child: _buildGameModeCard(
                            context: context,
                            title: "Spelling\nGame",
                            icon: "assets/spelling_bee.png",
                            isLocked: false,
                            screenWidth: screenWidth,
                            gameScreen: Home(),
                          ),
                        ),
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

  Widget _buildGameModeCard({
    required BuildContext context,
    required String title,
    required String icon,
    required bool isLocked,
    required double screenWidth,
    required Widget gameScreen,
  }) {
    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => gameScreen),
              );
            },
      child: Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.containerOpaqueColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(width: screenWidth * 0.16),
                    AppColors.gradientText(
                      title,
                      screenWidth * 0.06,
                    ),
                  ],
                ),
                if (isLocked)
                  CustomPaint(
                    size: Size(screenWidth * 0.1, screenWidth * 0.1),
                    painter: GradientIconPainter(
                      icon: Icons.lock,
                      gradient: AppColors.textGradient,
                    ),
                  ),
              ],
            ),
            Positioned(
              left: -16,
              top: -10,
              child: Image.asset(
                icon,
                width: screenWidth * 0.18,
                height: screenWidth * 0.18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
