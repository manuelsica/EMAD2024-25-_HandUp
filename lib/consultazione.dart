import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_up_interface/main.dart';
import "sidemenu.dart";
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:hand_up_interface/consultazione_lettera.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const Consultazione());
  });
}
class Consultazione extends StatelessWidget {
  const Consultazione({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const ConsultazioneScreen(),
    );
  }
}
class ConsultazioneScreen extends StatefulWidget {
  const ConsultazioneScreen({Key? key}) : super(key: key);

  @override
  _ConsultazioneScreenState createState() => _ConsultazioneScreenState();
}

class _ConsultazioneScreenState extends State<ConsultazioneScreen>
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
                            height: screenHeight * 0.15,
                            width: screenWidth * 0.9,
                            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
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
                                
                                Padding(
                                  padding: const EdgeInsets.all(0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Libreria di Consultazione',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.06,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textColor2,
                                      
                                        ),
                                        
                                      ),
                                      const SizedBox(height: 40),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Container(
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
                            'Seleziona una Lettera',
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color : AppColors.textColor1
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Lobby List
                          Column(
                              children: List.generate(26, (index) {
                                // Genera una lettera a partire dall'indice
                                String lettera = String.fromCharCode(65 + index); // 65 è il codice ASCII di 'A'
                                return _buildLobbyItem(
                                  lettera: lettera,
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  context: context, // Passa il contesto per la navigazione
                                );
                              }),
                            ),
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
        ],
      ),
    );
  }
  Widget _buildLobbyItem({
  required String lettera,
  required double screenWidth,
  required double screenHeight,
  required BuildContext context, // Aggiunto per gestire Navigator
}) {
  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
       builder: (context) => ConsultazioneLettera(lettera: lettera),
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.containerOpaqueColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scritta "LETTERA"
                Text(
                  'LETTERA',
                  style: TextStyle(
                    fontSize: screenWidth * 0.048,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor1, // Colore specificato nel TextStyle
                  ),
                ),
                SizedBox(width: screenWidth * 0.02), // Spaziatura tra "LETTERA" e la lettera
                // Lettera specifica
                Text(
                  lettera,
                  style: TextStyle(
                    fontSize: screenWidth * 0.048,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor3, // Colore specificato nel TextStyle
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

    }