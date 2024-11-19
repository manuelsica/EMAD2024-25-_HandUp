import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_up_interface/main.dart';
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MultiplayerHome());
  });
}

class MultiplayerHome extends StatelessWidget {
  const MultiplayerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const MultiplayerHomeScreen(),
    );
  }
}

class MultiplayerHomeScreen extends StatefulWidget {
  const MultiplayerHomeScreen({Key? key}) : super(key: key);

  @override
  _MultiplayerHomeScreenState createState() => _MultiplayerHomeScreenState();
}

class _MultiplayerHomeScreenState extends State<MultiplayerHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isContainerVisible = false;
  String _lobbyType = 'Spelling';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleContainer() {
    setState(() {
      _isContainerVisible = !_isContainerVisible;
      if (_isContainerVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: SideMenu(),
      body: Stack(
        children: [
          Container(
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
                        const Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Text('U',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Username',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  '000 Punti',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
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
                          // Create Game Card
                          Container(
                            height: screenHeight * 0.3,
                            width: screenWidth * 0.9,
                            padding: const EdgeInsets.fromLTRB(20, 20, 60, 60),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: AppColors.textColor2,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  right: -screenWidth * 0.35,
                                  bottom: -screenHeight * 0.4,
                                  child: Image.asset(
                                    'assets/hand_coin.png',
                                    width: screenWidth * 0.9,
                                    height: screenHeight * 0.9,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Crea una partita',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.07,
                                          fontWeight: FontWeight.bold,
                                          foreground: Paint()
                                            ..shader = AppColors.getTextShader(
                                                screenWidth, screenHeight),
                                        ),
                                      ),
                                      const SizedBox(height: 40),
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
                                                offset: const Offset(0, 0),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color.fromARGB(
                                                      110, 214, 57, 196),
                                                  Color.fromARGB(
                                                      110, 255, 0, 208),
                                                  Color.fromARGB(
                                                      110, 140, 53, 232)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.transparent,
                                                  blurRadius: 20,
                                                  spreadRadius: 4,
                                                  offset: const Offset(0, 0),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 15,
                                                        vertical: 5),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                elevation: 0,
                                                shadowColor: Colors.transparent,
                                              ),
                                              onPressed: _toggleContainer,
                                              child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 15,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    "Crea una Lobby",
                                                  )),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Join Game Section
                          Text(
                            'Unisciti ad una Partita',
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = AppColors.getTextShader(
                                    screenWidth, screenHeight),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Lobby List
                          _buildLobbyItem(
                              title: 'Lobby #1',
                              players: '1/4',
                              owner: 'NexusDreamer',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight),
                          _buildLobbyItem(
                              title: 'Lobby #2',
                              players: '1/4',
                              owner: 'LuminousEnigma',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              isLocked: true),
                          _buildLobbyItem(
                              title: 'Lobby #3',
                              players: '3/4',
                              owner: 'VortexScribe',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight),
                          _buildLobbyItem(
                              title: 'Lobby #4',
                              players: '3/4',
                              owner: 'StellarVoyage',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              isLocked: true),
                          _buildLobbyItem(
                              title: 'Lobby #5',
                              players: '2/4',
                              owner: 'Voyage',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              isLocked: true),
                          // Back Button
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SlideTransition(
            position: _offsetAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenHeight * 0.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.purple.shade900,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Builder(builder: (BuildContext context) {
                          return IconButton(
                            icon: CustomPaint(
                              size: Size(24, 24),
                              painter: GradientIconPainter(
                                icon: Icons.close,
                                gradient: AppColors.textGradient,
                              ),
                            ),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          );
                        }),
                      ),
                      Text(
                        'Create Lobby',
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = AppColors.getTextShader(
                                screenWidth, screenHeight),
                        ),                      
                      ),                      
                      SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter lobby name',
                          hintStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.purple.shade800,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          value: _lobbyType,
                          dropdownColor: Colors.purple.shade800,
                          style: TextStyle(color: Colors.white),
                          icon:
                              Icon(Icons.arrow_drop_down, color: Colors.white),
                          isExpanded: true,
                          underline: SizedBox(),
                          menuMaxHeight: 200,
                          onChanged: (String? newValue) {
                            setState(() {
                              _lobbyType = newValue!;
                            });
                          },
                          items: <String>["Spelling", "Matematica", "Scarabeo", "Impiccato"]
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),                      
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _toggleContainer,
                        child: Text('Create', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyItem({
    required String title,
    required String players,
    required String owner,
    required double screenWidth,
    required double screenHeight,
    bool isLocked = false,
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
              "assets/swords_icon.png",
              width: screenWidth * 0.3,
              height: screenHeight * 0.3,
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(100, 10, 20, 10),
            title: Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.048,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = AppColors.getTextShader(screenWidth, screenHeight),
              ),
            ),
            subtitle: Row(
              children: [
                CustomPaint(
                    size: Size(screenWidth * 0.04, screenWidth * 0.04),
                    painter: GradientIconPainter(
                      icon: Icons.person,
                      gradient: AppColors.textGradient,
                    )),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  players,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Owner:',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: screenWidth * 0.03,
                  ),
                ),
                Text(
                  owner,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                if (isLocked)
                  CustomPaint(
                      size: Size(screenWidth * 0.035, screenWidth * 0.035),
                      painter: GradientIconPainter(
                        icon: Icons.lock,
                        gradient: AppColors.textGradient,
                      ))
              ],
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}