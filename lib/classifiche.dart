import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';
import "top_bar.dart";

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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LeaderboardHomeScreen(),
    );
  }
}

class LeaderboardHomeScreen extends StatelessWidget {
  const LeaderboardHomeScreen({Key? key}) : super(key: key);

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
                  username: "USERNAME",
                  points: 1000,
                  showMenu: true,
                  showUser: true),
              // Current User Position
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
                          '120',
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
                    child: AppColors.gradientText("Sei in posizione:", screenWidth * 0.06),
                  ),
                ],
              ),

              // Leaderboard Title
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: 
                  AppColors.gradientText("Classifica Generale:", screenWidth * 0.07)
                ),
              ),

              // Leaderboard List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildLeaderboardItem(
                      position: '1',
                      username: 'PixelGuru',
                      points: '13324',
                      avatar: 'P',
                      screenWidth: screenWidth,
                      isFirst: true,
                      screenHeight: screenHeight,
                    ),
                    _buildLeaderboardItem(
                      position: '2',
                      username: 'AstroWizard',
                      points: '9742',
                      avatar: 'A',
                      screenWidth: screenWidth,
                      isSecond: true,
                      screenHeight: screenHeight,
                    ),
                    _buildLeaderboardItem(
                      position: '3',
                      username: 'NeonNomad',
                      points: '9542',
                      avatar: 'N',
                      screenWidth: screenWidth,
                      isThird: true,
                      screenHeight: screenHeight,
                    ),
                    _buildLeaderboardItem(
                      position: '4',
                      username: 'QuantumTraveler',
                      points: '9342',
                      avatar: 'Q',
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildLeaderboardItem(
                      position: '5',
                      username: 'MysticCoder',
                      points: '9442',
                      avatar: 'M',
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildLeaderboardItem(
                      position: '6',
                      username: 'StarryByte',
                      points: '9342',
                      avatar: 'S',
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  //Build the single leaderboard item
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
              SizedBox(width: avatarSize + 16),
              //Visualizzazione posizione
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: isFirst ? 12 : 10),
                      child: Row(
                        children: [
                          isFirst ? 
                            AppColors.firstPlaceGradientText(
                                '$position' + "° Posto", isFirst ? screenWidth * 0.1 : screenWidth * 0.07)
                          : 
                            AppColors.gradientText(
                                '$position' + "° Posto", isFirst ? screenWidth * 0.1 : screenWidth * 0.07)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              //Visualizzazione punti
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: isFirst ? 35 :  isSecond ? 25 :17),
                  AppColors.gradientText("Punti: " + points, screenWidth * 0.035),
                ],
              ),
            ],
          ),
        ),
        //Display Avatar
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
        //Display Username
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
}
