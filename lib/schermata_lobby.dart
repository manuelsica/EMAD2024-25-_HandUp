import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({Key? key}) : super(key: key);

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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(builder: (BuildContext context) {
                      return IconButton(
                        icon: CustomPaint(
                          size: Size(24, 24),
                          painter: GradientIconPainter(
                            icon: Icons.menu,
                            gradient: AppColors.textGradient,
                          ),
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    }),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child:
                              Text('U', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Username',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '000 Punti',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lobby Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CustomPaint(
                      size: Size(screenWidth * 0.04, screenHeight * 0.04),
                      painter: GradientIconPainter(
                        icon: Icons.timer,
                        gradient: AppColors.textGradient,
                      ),
                    ),
                    // Icon(
                    //   Icons.timer,
                    //   color: AppColors.textColor1,
                    //   size: screenWidth * 0.08,
                    // ),
                    SizedBox(width: 30),
                    AppColors.gradientText(
                      'Lobby di USERNAME',
                      screenWidth * 0.06,
                    ),
                  ],
                ),
              ),

              // Lobby Info Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.purple.shade900.withOpacity(0.3),
                  // border: Border.all(
                  //   color: AppColors.textColor1.withOpacity(0.3),
                  //   width: 2,
                  // ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Nome:', 'LightingRound', screenWidth),
                    SizedBox(height: 10),
                    _buildInfoRow('Gioco:', 'Spelling', screenWidth),
                    SizedBox(height: 10),
                    _buildInfoRow('Nr. Utenti:', '2/4', screenWidth),
                  ],
                ),
              ),

              // Participants Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CustomPaint(
                      size: Size(screenWidth * 0.03, screenHeight * 0.03),
                      painter: GradientIconPainter(
                        icon: Icons.group,
                        gradient: AppColors.textGradient,
                      ),
                    ),
                    SizedBox(width: 30),
                    AppColors.gradientText(
                      'Partecipanti',
                      screenWidth * 0.05,
                    ),
                  ],
                ),
              ),

              // Participants List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildParticipantTile('PixelGuru', 'P', screenWidth),
                    SizedBox(height: 12),
                    _buildParticipantTile('StormyNight', 'S', screenWidth),
                  ],
                ),
              ),

              // Start Game Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textColor1.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle start game
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textColor1.withOpacity(0.2),
                      foregroundColor: AppColors.textColor1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Inizia Partita',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: AppColors.textColor1.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
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

  Widget _buildInfoRow(String label, String value, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textColor1,
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.04,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(
      String username, String avatar, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.purple.shade900.withOpacity(0.3),
        // border: Border.all(
        //   color: AppColors.textColor1.withOpacity(0.3),
        //   width: 2,
        // ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: Text(
              avatar,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            username,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
