import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import "app_colors.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import "animated_button.dart";

class ScarabeoGameScreen extends StatefulWidget {
  final String playerName;
  final String opponentName;

  const ScarabeoGameScreen({
    Key? key,
    required this.playerName,
    required this.opponentName,
  }) : super(key: key);

  @override
  _ScarabeoGameScreenState createState() => _ScarabeoGameScreenState();
}

class _ScarabeoGameScreenState extends State<ScarabeoGameScreen>
    with SingleTickerProviderStateMixin {
  // Variabili per lo storage sicuro
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Variabili per il timer
  late AnimationController _timerController;
  String _timeString = "00:00";
  double _progress = 0.0;

  // Variabili per la fotocamera
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  // Variabili di stato del gioco
  int _currentTurn = 1;
  int _maxTurns = 15;
  String _detectedSign = '';
  bool _showWordInput = false;
  bool _showReplicaModal = false;
  bool _showJollyInput = false;
  String _currentWord = '';
  String _jollyValue = "_";
  List<String> _letters =
      List.generate(7, (index) => 'A'); // Placeholder letters

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTimer();
  }

  // Inizializzazione del timer
  void _initializeTimer() {
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1),
    )..addListener(() {
        setState(() {
          _progress = _timerController.value;
          int seconds = (_timerController.value * 60).floor();
          _timeString =
              "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
        });
      });

    _timerController.forward();
  }

  // Inizializzazione della fotocamera
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Errore inizializzazione fotocamera: $e');
    }
  }

  // Gestione del pulsante Parola
  void _handleWordButton() {
    setState(() {
      _showWordInput = true;
    });
  }

  // Gestione del pulsante Replica
  void _handleReplicaButton() {
    setState(() {
      _showWordInput = false;
      _showReplicaModal = true;
      _resetTimer();
    });
  }

  void _handleJollyValueButton() {
    setState(() {
      if (_showJollyInput == true){
        _showJollyInput = false;
      } else {
        _showJollyInput = true;
      }
    });
  }


  // Reset del timer
  void _resetTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Contenuto principale
          SafeArea(
            child: Column(
              children: [
                // Header con informazioni giocatori
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Player\n${widget.playerName}\nScore: 0',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      Column(
                        children: [
                          AppColors.gradientText(
                            'Turno ${_currentTurn}/${_maxTurns}',
                            screenWidth * 0.04,
                          ),
                          AppColors.gradientText(
                            'È il turno di: ${widget.playerName}',
                            screenWidth * 0.04,
                          ),
                        ],
                      ),
                      Text(
                        'Player\n${widget.opponentName}\nScore: 0',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Area principale di gioco
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomPaint(
                      painter: CrossPainter(),
                      child: Container(),
                    ),
                  ),
                ),

                // Timer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _timeString,
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                // Lettere disponibili
                Container(
                  height: 80,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _letters
                        .map((letter) => _buildLetterTile(letter))
                        .toList(),
                  ),
                ),

                // Pulsanti azione
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildActionButton("Parola", _handleWordButton, screenWidth, screenHeight),
                      SizedBox(height: 15),
                      _buildActionButton("Cambia tessere", () {}, screenWidth, screenHeight),
                      SizedBox(height: 15),
                      _buildActionButton("Passa turno", () {}, screenWidth, screenHeight),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Icona in basso a sinistra
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: IconButton(
                icon: CustomPaint(
                  size: Size(screenWidth * 0.045, screenHeight * 0.045),
                  painter: GradientIconPainter(
                    icon: Icons.dataset,
                    gradient: AppColors.textGradient,
                  ),
                ),
                onPressed: () {
                  // Navigator.pop(context);
                  _handleJollyValueButton();
                },
              ),
            ),
          ),

          // Icona in basso a destra
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: IconButton(
                icon: CustomPaint(
                  size: Size(screenWidth * 0.045, screenHeight * 0.045),
                  painter: GradientIconPainter(
                    icon: Icons.shopping_bag,
                    gradient: AppColors.textGradient,
                  ),
                ),
                onPressed: () {
                  // Navigator.pop(context);
                },
              ),
            ),
          ),

          // Modal per inserimento parola
          if (_showWordInput) _buildWordInputModal(screenWidth, screenHeight),

          if (_showJollyInput) _buildJollyValueInputModal(screenWidth, screenHeight),

          // Modal per replica
          if (_showReplicaModal) _buildReplicaModal(screenWidth, screenHeight),
        ],
      ),
    );
  }

  // Costruzione del tile per le lettere
  Widget _buildLetterTile(String letter, {int count = 1}) {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Costruzione dei pulsanti azione
  Widget _buildActionButton(String text, VoidCallback onPressed, double screenWidth, double screenHeight) {
    return  AnimatedButton(
      onPressed: onPressed,
      isLocked: false,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 233, 30, 196).withOpacity(0.8),
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
                backgroundColor: Colors.purple,
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
                onPressed;
              },
              child: Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: Text(
                    text,
                  ))),
        ),
      ),
    );
  }

  // Modal per inserimento parola
  Widget _buildWordInputModal(double screenWidth, double screenHeight){
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppColors.gradientText(
                'Inserisci parola',
                screenWidth * 0.07,
              ),
              SizedBox(height: 16),
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.pink.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                onChanged: (value) => _currentWord = value,
              ),
              SizedBox(height: 16),
              _buildActionButton("Replica", _handleReplicaButton, screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJollyValueInputModal(double screenWidth, double screenHeight) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inserisci un valore per il jolly',
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.pink.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                ),
                onChanged: (value) => _jollyValue = value,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1), //limita la dimensione di input a una lettera
                ]
              ),
              SizedBox(height: 16),
              _buildActionButton(
                  "Conferma", _handleJollyValueButton, screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }


  // Modal per replica
  Widget _buildReplicaModal(double screenWidth, double screenHeight){
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppColors.gradientText(
                'Replica',
                screenWidth * 0.07
              ),
              SizedBox(height: 16),
              //Camera feed
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(screenWidth * 0.0000001),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: screenWidth * 0.005, // Proporzionale
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        (screenWidth * 0.03) - screenWidth * 0.005),
                    child: _isCameraInitialized
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return FittedBox(
                                fit: BoxFit
                                    .cover, // Mantiene il rapporto d'aspetto e riempie il contenitore
                                child: SizedBox(
                                  width: _cameraController
                                      .value.previewSize!.height,
                                  height: _cameraController
                                      .value.previewSize!.width,
                                  child: CameraPreview(_cameraController),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.textColor1,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              AppColors.gradientText(
                'Segno rilevato: $_detectedSign',
                screenWidth * 0.03
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _currentWord.toUpperCase().split('').map((letter) => _buildLetterTile(letter)).toList(),
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.blue.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
              SizedBox(height: 16),
              Text(
                _timeString,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              _buildActionButton("Passa turno", () {
                setState(() {
                  _showReplicaModal = false;
                });
              }, screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }
}

// Painter per il pattern a X
class CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
