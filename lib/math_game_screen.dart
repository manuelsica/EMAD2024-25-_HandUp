import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import "app_colors.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import "animated_button.dart";

class MathGameScreen extends StatefulWidget {
  final List<String> questions;

  const MathGameScreen({
    Key? key,
    required this.questions,
  }) : super(key: key);

  @override
  _MathGameScreenState createState() => _MathGameScreenState();
}

class _MathGameScreenState extends State<MathGameScreen>
    with SingleTickerProviderStateMixin {
  // Secure storage for sensitive data
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Timer related variables
  late AnimationController _timerController;
  String _timeString = "00:30";
  double _progress = 0.0;

  // Camera related variables
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  // Game state variables
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  String detectedSign = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTimer();
  }

  // Initialize the timer
  void _initializeTimer() {
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
        setState(() {
          _progress = _timerController.value;
          int seconds = (30 * (1 - _timerController.value)).round();
          _timeString = "00:${seconds.toString().padLeft(2, '0')}";
        });
      });

    _timerController.forward();
  }

  // Initialize the camera
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
      print('Error initializing camera: $e');
    }
  }

  // Handle detected sign (placeholder function)
  void _handleDetectedSign(String sign) {
    setState(() {
      detectedSign = sign;
    });

    // TODO: Implement actual logic for checking answers
    bool isCorrect = sign == '+' || sign == '-' || sign == '*' || sign == '/';
    if (isCorrect) {
      correctAnswers++;
      _moveToNextQuestion();
    }
  }

  // Move to the next question
  void _moveToNextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _resetTimer();
      });
    } else {
      _endGame();
    }
  }

  // Reset the timer
  void _resetTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  // End the game
  void _endGame() {
    // TODO: Implement navigation to results screen
    print('Game ended. Correct answers: $correctAnswers');
    Navigator.pop(context);
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
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Container(
                margin:
                    EdgeInsets.fromLTRB(screenWidth * 0.04, screenWidth * 0.04, screenWidth * 0.04, screenWidth * 0.04 / 2),
                height: screenHeight * 0.005,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular((screenHeight * 0.005) / 2),
                ),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                          AppColors.textColor1,
                          AppColors.textColor3,
                          _progress,
                        ) ??
                        AppColors.textColor1,
                  ),
                ),
              ),
        
              // Camera Feed
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(screenWidth * 0.04),
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
              // Detected sign text
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                child: AppColors.gradientText(
                  "Segno rilevato: $detectedSign",
                  screenWidth * 0.05,
                ),
              ),

              // Math question
              Container(
                height: screenWidth * 0.2,
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Center(
                  child: AppColors.gradientText(
                    widget.questions[currentQuestionIndex],
                    screenWidth * 0.08,
                  ),
                ),
              ),

              // Controls
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      icon: CustomPaint(
                        size: Size(screenWidth * 0.05, screenHeight * 0.05),
                        painter: GradientIconPainter(
                          icon: Icons.arrow_back,
                          gradient: AppColors.textGradient,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    // Timer
                    Text(
                      _timeString,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Skip button
                    AnimatedButton(
                      onPressed: () {},
                      isLocked: false,
                      child: Container(
                        width: screenWidth * 0.2,
                        height: screenHeight * 0.06,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular((screenHeight * 0.06) / 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 233, 30, 196)
                                  .withOpacity(0.8),
                              blurRadius: 20,
                              spreadRadius: 4,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.symmetric(
                              horizontal: (screenWidth * 0.2) * 0.1,
                              vertical: (screenHeight * 0.06) * 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  (screenHeight * 0.06) / 2),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: () {
                            _moveToNextQuestion();
                          },
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }
}
