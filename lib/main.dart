import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });
  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: SideMenu(),
      body: Container(
        decoration: const BoxDecoration(
          // gradient: AppColors.containerBorderGradient,
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
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'USERNAME',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              'punti: 1000',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Top Card
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 60, 30),
                        height: screenHeight * 0.35,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                              color: AppColors.textColor2, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              right: -screenWidth * 0.57,
                              bottom: -screenHeight * 0.66,
                              child: Image.asset(
                                'assets/hand_icon.png',
                                width: screenWidth * 1.5,
                                height: screenHeight * 1.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child:
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Allenati con parole casuali',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.07,
                                        fontWeight: FontWeight.bold,
                                        foreground: Paint()
                                          ..shader = AppColors.getTextShader(
                                            screenWidth,
                                            screenHeight,
                                          ),
                                        // color: Colors.pink,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    
                                    Padding(
                                      padding: const EdgeInsets.only(right: 80),
                                      child:
                                        Column(
                                          children: [
                                            Text(
                                              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur imperdiet ex vel libero pharetra, vita a posuere purus egestas.',
                                              style: TextStyle(color: Colors.grey[300]),
                                            ),
                                            const SizedBox(height: 20),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(30),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.pink.withOpacity(0.8),
                                                          blurRadius: 20,
                                                          spreadRadius: 4,
                                                          offset: const Offset(0, 0),
                                                        ),
                                                      ],
                                                    ),
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.pink,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 5,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    elevation: 0,
                                                    shadowColor: Colors.transparent,
                                                  ),
                                                  onPressed: () {},
                                                  child: const Padding(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 15,
                                                        vertical: 8,
                                                      ),
                                                      child: const Text('Parole casuali',)
                                                  )
                                                ),
                                            ),
                                        )],
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
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      _buildMenuItem(
                        title: 'Animali',
                        imageUrl: 'assets/animal_icon.png',
                        isLocked: true,
                        points: 350,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      _buildMenuItem(
                        title: 'Cibi',
                        imageUrl: 'assets/food_icon.png',
                        isLocked: true,
                        points: 350,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      _buildMenuItem(
                        title: 'Svago',
                        imageUrl: 'assets/tv_icon.png',
                        isLocked: true,
                        points: 350,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      _buildMenuItem(
                        title: 'Varie',
                        imageUrl: 'assets/tv_icon.png',
                        isLocked: true,
                        points: 350,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            title: Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.048,
                // color: Colors.pink,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = AppColors.getTextShader(screenWidth, screenHeight),
              ),
            ),
            trailing: isLocked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.getTextShader(screenWidth, screenHeight),
                        child: const Icon(Icons.lock, color: Color.fromARGB(71, 255, 255, 255)),
                      ),
                      // const Icon(Icons.lock, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Costo: $points punti',
                        style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows:[
                              Shadow(
                                color: Colors.white.withOpacity(1.0),
                                blurRadius: 10,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 20,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 30,
                                offset: Offset(0, 0),
                              ),
                            ]
                        ),
                      ),
                    ],
                  )
                : null,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
