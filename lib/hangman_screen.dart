import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:handup/difficulty_selection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:handup/risultati_singleplayer.dart';
import "app_colors.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import "animated_button.dart";
import "backend_config.dart";
import "risultati_singleplayer.dart";
import "selezione_gioco.dart";

class HangmanGameScreen extends StatefulWidget {
  final List<String> words;

  const HangmanGameScreen({
    Key? key,
    required this.words,
  }) : super(key: key);

  @override
  _HangmanGameScreenState createState() => _HangmanGameScreenState();
}

class _HangmanGameScreenState extends State<HangmanGameScreen>
    with SingleTickerProviderStateMixin {
  // Secure storage for sensitive data
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Variabili per il timer
  late AnimationController _timerController;
  String _timeString = "00:00";
  double _progress = 0.0;

  // Variabili per la fotocamera
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  // Variabili di stato del gioco
  int _currentWordIndex = 0;
  int _lives = 6; // Numero di tentativi rimasti
  String _predictedCharacter = 'Nessuna predizione';
  bool _isProcessing = false;
  DateTime _lastSent = DateTime.now();
  Set<String> _usedLetters = {}; // Lettere già utilizzate
  List<bool> _letterRevealed = []; // Stato di rivelazione delle lettere
  int _correctAnswers = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;



  final String serverUrl = BackendConfig.predictUrl;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTimer();
    _initializeWord();
  }

  // Initialize the timer
  void _initializeTimer() {
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 5),
    )..addListener(() {
        setState(() {
          _progress = _timerController.value;
          int seconds = (_timerController.value * 300).floor();
          _timeString = "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _timer?.cancel();
          _endGame();
        }
      });

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
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
      _startImageStream();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  // Inizializzazione della parola corrente
  void _initializeWord() {
    String currentWord = widget.words[_currentWordIndex].toUpperCase();
    _letterRevealed = List<bool>.filled(currentWord.length, false);
  }

  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) async {
      final now = DateTime.now();

      // Processa un frame solo ogni 500 ms
      if (_isProcessing || now.difference(_lastSent).inMilliseconds < 1000) {
        return;
      }

      _isProcessing = true;
      _lastSent = now;

      Uint8List? jpegBytes = await _convertCameraImage(image);
      if (jpegBytes != null) {
        Map<String, dynamic>? response = await _sendImageToServer(jpegBytes);
        if (response != null && response.containsKey('predictions')) {
          if (response['predictions'].isNotEmpty) {
            String predictedChar =
                response['predictions'][0]['character'] ?? "Nessuna predizione";
            setState(() {
              _predictedCharacter = predictedChar;
            });
            _handlePredictedCharacter(predictedChar);
          } else {
            setState(() {
              _predictedCharacter = "Nessuna mano rilevata";
            });
          }
        }
      }

      _isProcessing = false;
    });
  }


  void _handlePredictedCharacter(String predictedChar) {
    String currentWord = widget.words[_currentWordIndex].toUpperCase();
    String char = predictedChar.toUpperCase();

    bool letterFound = false;

    for (int i = 0; i < currentWord.length; i++) {
      if (currentWord[i] == char && !_letterRevealed[i]) {
        setState(() {
          _letterRevealed[i] = true;
        });
        letterFound = true;
      }
    }

    if (!letterFound) {
      if (!_usedLetters.contains(char)){
        setState(() {
          _lives--;
          if (_lives <= 0) {
            _endGame();
          }
        });
      }

      if (!_usedLetters.contains(char) && !currentWord.contains(char)) {
        _usedLetters.add(char);
      }

    }

    // Se tutte le lettere sono state riconosciute, passa alla prossima parola
    if (_letterRevealed.every((status) => status)) {
      _correctAnswers++;
      _moveToNextWord();
    }
  }


  // Passa alla prossima parola
  void _moveToNextWord() {
    if (_currentWordIndex < widget.words.length - 1) {
      setState(() {
        _currentWordIndex++;
        _usedLetters.clear();
        _initializeWord();
      });
    } else {
      _endGame();
    }
  }

  Future<Map<String, dynamic>?> _sendImageToServer(Uint8List imageBytes) async {
    try {
      String base64Image = base64Encode(imageBytes);
      String platform = Platform.isAndroid ? "android" : "ios";

      // Recupera il token JWT salvato
      final storage = FlutterSecureStorage();
      String? jwtToken = await storage.read(
          key: 'access_token'); // Usa 'access_token' invece di 'jwt_token'

      if (jwtToken == null) {
        debugPrint("Token JWT mancante.");
        // Mostra un messaggio di errore all'utente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Token di autenticazione mancante. Effettua il login di nuovo.")),
        );
        return null;
      }

      print('Invio richiesta a: $serverUrl');
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Bearer $jwtToken", // Aggiungi il token nell'header Authorization
        },
        body: jsonEncode({"image": base64Image, "platform": platform}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Errore dal server: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore dal server: ${response.body}")),
        );
        return null;
      }
    } catch (e) {
      debugPrint("Errore nella richiesta al server: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore nella richiesta al server: $e")),
      );
      return null;
    }
  }

  Future<Uint8List?> _convertCameraImage(CameraImage image) async {
    try {
      if (image.planes.isEmpty) {
        print("Errore: Nessun piano disponibile nell'immagine.");
        return null;
      }

      if (image.format.group == ImageFormatGroup.yuv420) {
        Uint8List jpgBytes = _convertYUV420toImageColor(image);

        img.Image? decodedImage = img.decodeImage(jpgBytes);
        if (decodedImage != null) {
          img.Image orientedImage = img.bakeOrientation(decodedImage);
          return Uint8List.fromList(img.encodeJpg(orientedImage, quality: 80));
        } else {
          print("Errore: Decodifica immagine fallita.");
          return null;
        }
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888toImageColor(image);
      } else {
        print('Formato immagine non supportato: ${image.format.group}');
        return null;
      }
    } catch (e) {
      print('Errore nella conversione dell\'immagine: $e');
      return null;
    }
  }

  Uint8List _convertYUV420toImageColor(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 2;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      int uvRow = y >> 1;
      for (int x = 0; x < width; x++) {
        int uvCol = x >> 1;
        int indexY = y * image.planes[0].bytesPerRow + x;
        int indexUV = uvRow * uvRowStride + uvCol * uvPixelStride;

        if (indexUV + 1 >= image.planes[1].bytes.length ||
            indexY >= image.planes[0].bytes.length) {
          continue;
        }

        int yValue = image.planes[0].bytes[indexY];
        int uValue = image.planes[1].bytes[indexUV];
        int vValue = image.planes[2].bytes[indexUV];

        int c = yValue - 16;
        int d = uValue - 128;
        int e = vValue - 128;

        int r = (1.164 * c + 1.596 * e).round().clamp(0, 255);
        int g = (1.164 * c - 0.392 * d - 0.813 * e).round().clamp(0, 255);
        int b = (1.164 * c + 2.017 * d).round().clamp(0, 255);

        imgBuffer.setPixelRgb(x, y, r, g, b);
      }
    }

    return Uint8List.fromList(img.encodeJpg(imgBuffer, quality: 80));
  }

  Uint8List _convertBGRA8888toImageColor(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image imgBuffer = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int byteIndex = y * image.planes[0].bytesPerRow + x * 4;
        if (byteIndex + 3 >= image.planes[0].bytes.length) continue;

        int b = image.planes[0].bytes[byteIndex];
        int g = image.planes[0].bytes[byteIndex + 1];
        int r = image.planes[0].bytes[byteIndex + 2];

        imgBuffer.setPixelRgb(x, y, r, g, b);
      }
    }

    return Uint8List.fromList(img.encodeJpg(imgBuffer, quality: 80));
  }



  // Costruzione della parola visualizzata
  String _buildDisplayWord() {
    String currentWord = widget.words[_currentWordIndex].toUpperCase();
    return currentWord
        .split('')
        .asMap()
        .entries
        .map((entry) => _letterRevealed[entry.key] ? entry.value : '_')
        .join(' ');
  }


  // Reset the timer
  void _resetTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  // End the game
  void _endGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RisultatiPartitaScreen(gameMode: "hangman", correctAnswers: _correctAnswers, gameTime: _elapsedSeconds),
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _timer?.cancel();
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
                margin: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    screenWidth * 0.04,
                    screenWidth * 0.04,
                    screenWidth * 0.04 / 2),
                height: screenHeight * 0.005,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular((screenHeight * 0.005) / 2),
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

              Row(
                children: [
                  // Lives
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Row(
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            _lives >= 1
                              ? <double>[
                                  1, 0, 0, 0, 0,
                                  0, 1, 0, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]
                              : <double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ], 
                          ),         
                          child: Image(
                            image: _lives >= 1
                                ? AssetImage('assets/letterav.png')
                                : AssetImage("assets/letteraa.png"),
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            _lives >= 2
                              ? <double>[
                                  1, 0, 0, 0, 0,
                                  0, 1, 0, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]
                              : <double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ], 
                          ),         
                          child: Image(
                            image: _lives >= 2
                                ? AssetImage('assets/letterav.png')
                                : AssetImage("assets/letteraa.png"),
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            _lives >= 3
                              ? <double>[
                                  1, 0, 0, 0, 0,
                                  0, 1, 0, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]
                              : <double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ], 
                          ),         
                          child: Image(
                            image: _lives >= 3
                                ? AssetImage('assets/letterav.png')
                                : AssetImage("assets/letteraa.png"),
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            _lives >= 4
                              ? <double>[
                                  1, 0, 0, 0, 0,
                                  0, 1, 0, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]
                              : <double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ], 
                          ),         
                          child: Image(
                            image: _lives >= 4
                                ? AssetImage('assets/letterav.png')
                                : AssetImage("assets/letteraa.png"),
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            _lives >= 5
                              ? <double>[
                                  1, 0, 0, 0, 0,
                                  0, 1, 0, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]
                              : <double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ], 
                          ),         
                          child: Image(
                            image: _lives >= 5
                                ? AssetImage('assets/letterav.png')
                                : AssetImage("assets/letteraa.png"),
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            _lives >= 6
                              ? <double>[
                                  1, 0, 0, 0, 0,
                                  0, 1, 0, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]
                              : <double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ], 
                          ),         
                          child: Image(
                            image: _lives >= 6
                                ? AssetImage('assets/letterav.png')
                                : AssetImage("assets/letteraa.png"),
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Camera Feed
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
              // Detected sign text
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                child: AppColors.gradientText(
                  "Segno rilevato: $_predictedCharacter",
                  screenWidth * 0.05,
                ),
              ),

              // Parola da indovinare
              Container(
                width: screenWidth * 0.9,
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.textColor1.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AppColors.gradientText(
                    _buildDisplayWord(),
                    screenWidth * 0.08,
                  ),
                ),
              ),


              // Lettere utilizzate
              Container(
                width: screenWidth * 0.9,
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    AppColors.gradientText(
                      'Lettere utilizzate:',
                      screenWidth * 0.05,
                    ),
                    Text(
                      _usedLetters.join(', '),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ],
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
                            _moveToNextWord();
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
