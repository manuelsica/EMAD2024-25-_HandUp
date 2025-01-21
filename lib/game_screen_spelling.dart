import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import "app_colors.dart";
import 'package:google_fonts/google_fonts.dart';
import "sidemenu.dart"; 
import 'risultati_singleplayer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "top_bar.dart";
import "backend_config.dart";
import "animated_button.dart";

class GameScreen extends StatefulWidget {
  final List<String> words; // Lista di parole passate dal ModalitaScreen

  const GameScreen({Key? key, required this.words}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  String _timeString = "00:00";
  double _progress = 0.0;
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  String _predictedCharacter = "Nessuna predizione"; // Risultato dal server
  bool _isProcessing = false; // Stato per prevenire richieste duplicate
  DateTime _lastSent = DateTime.now(); // Ultimo invio

  final String serverURL = BackendConfig.predictUrl;
      // "https://2ddb-95-238-150-172.ngrok-free.app/predict/";

  // Variabili per la gestione delle parole e delle lettere
  int _currentWordIndex = 0; // Indice della parola corrente
  List<bool> _letterCompletionStatus = []; // Stato di completamento delle lettere

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 5),
    )
      ..addListener(() {
        setState(() {
          _progress = _timerController.value;
          int seconds = (_timerController.value * 300).floor();
          _timeString =
              "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Quando il timer termina, naviga alla schermata dei risultati
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RisultatiPartitaScreen(),
            ),
          );
        }
      });
    _timerController.forward();

    // Inizializza lo stato delle lettere della prima parola
    if (widget.words.isNotEmpty) {
      _initializeLetterCompletion();
    }
  }

  void _initializeLetterCompletion() {
    String currentWord = widget.words[_currentWordIndex].toUpperCase();
    _letterCompletionStatus =
        List<bool>.filled(currentWord.length, false);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium, // Usa una risoluzione più bilanciata
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
      _startImageStream();
    } catch (e) {
      print('Errore durante l\'inizializzazione della fotocamera: $e');
    }
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
            String predictedChar = response['predictions'][0]['character'] ?? "Nessuna predizione";
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
      if (currentWord[i] == char && !_letterCompletionStatus[i]) {
        setState(() {
          _letterCompletionStatus[i] = true;
        });
        letterFound = true;
      }
    }

    // Se tutte le lettere sono state riconosciute, passa alla prossima parola
    if (_letterCompletionStatus.every((status) => status)) {
      _moveToNextWord();
    }
  }

  void _moveToNextWord() {
    if (_currentWordIndex < widget.words.length - 1) {
      setState(() {
        _currentWordIndex++;
        _initializeLetterCompletion();
        _predictedCharacter = "Nessuna predizione";
      });
    } else {
      // Hai completato tutte le parole
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hai completato tutte le parole!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RisultatiPartitaScreen(),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _sendImageToServer(Uint8List imageBytes) async {
  try {
    String base64Image = base64Encode(imageBytes);
    String platform = Platform.isAndroid ? "android" : "ios";

    // Recupera il token JWT salvato
    final storage = FlutterSecureStorage();
    String? jwtToken = await storage.read(key: 'access_token'); // Usa 'access_token' invece di 'jwt_token'

    if (jwtToken == null) {
      debugPrint("Token JWT mancante.");
      // Mostra un messaggio di errore all'utente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token di autenticazione mancante. Effettua il login di nuovo.")),
      );
      return null;
    }

    print('Invio richiesta a: $serverURL');
    final response = await http.post(
      Uri.parse(serverURL),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $jwtToken", // Aggiungi il token nell'header Authorization
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

  Widget _buildOptionButton(String letter, double buttonSize, double borderRadius, bool isCompleted) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textColor1.withOpacity(0.2),
            AppColors.textColor2.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: isCompleted ? Colors.green : AppColors.textColor1.withOpacity(0.3),
          width: buttonSize * 0.033, // Proporzionale
        ),
        color: isCompleted ? Colors.green : Colors.transparent,
      ),
      child: Center(
        child: Text(
          letter, // Mostra la lettera specifica
          style: TextStyle(
            fontSize: buttonSize * 0.4, // Dimensione proporzionale
            color: isCompleted ? Colors.white : AppColors.textColor1,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ottieni le dimensioni dello schermo
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Definisci proporzioni relative
    final padding = screenWidth * 0.04; // 4% dello schermo
    final progressBarHeight = screenHeight * 0.005; // 0.5% dello schermo
    final cameraMargin = screenWidth * 0.04; // 4% dello schermo
    final cameraBorderRadius = screenWidth * 0.03; // 3% dello schermo
    final optionButtonSize = screenWidth * 0.12; // 12% dello schermo
    final optionButtonBorderRadius = screenWidth * 0.02; // 2% dello schermo
    final bottomIconSize = screenWidth * 0.05; // 5% dello schermo
    final bottomIconButtonSize = bottomIconSize; // Mantenere proporzionale
    final timeFontSize = screenWidth * 0.05; // 5% dello schermo
    final predictedTextFontSize = screenWidth * 0.04; // 4% dello schermo
    final skipButtonWidth = screenWidth * 0.2; // 20% dello schermo
    final skipButtonHeight = screenHeight * 0.06; // 6% dello schermo
    final skipButtonFontSize = screenWidth * 0.04; // 4% dello schermo

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              Container(
                margin: EdgeInsets.fromLTRB(padding, padding, padding, padding / 2),
                height: progressBarHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(progressBarHeight / 2),
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
                  margin: EdgeInsets.all(cameraMargin),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: screenWidth * 0.005, // Proporzionale
                    ),
                    borderRadius: BorderRadius.circular(cameraBorderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cameraBorderRadius - screenWidth * 0.005),
                    child: _isCameraInitialized
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return FittedBox(
                                fit: BoxFit.cover, // Mantiene il rapporto d'aspetto e riempie il contenitore
                                child: SizedBox(
                                  width: _cameraController.value.previewSize!.height,
                                  height: _cameraController.value.previewSize!.width,
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

              // Predicted Character
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                child: AppColors.gradientText(
                  "Segno rilevato: $_predictedCharacter",
                  predictedTextFontSize,
                ),
              ),

              // Option Buttons per la parola corrente
              Container(
                margin: EdgeInsets.all(padding),
                height: optionButtonSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.words[_currentWordIndex].toUpperCase().split('').asMap().entries.map((entry) {
                    int idx = entry.key;
                    String letter = entry.value;
                    bool isCompleted = _letterCompletionStatus[idx];
                    return Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding * 0.1),
                        child: _buildOptionButton(letter, optionButtonSize, optionButtonBorderRadius, isCompleted),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Bottom Controls
              Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Pulsante Indietro
                    IconButton(
                      icon: CustomPaint(
                        size: Size(bottomIconButtonSize, bottomIconButtonSize),
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
                        fontSize: timeFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Bottone Skip
                    AnimatedButton(
                      onPressed: () {},
                      isLocked: false,
                      child: Container(
                        width: skipButtonWidth,
                        height: skipButtonHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(skipButtonHeight / 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 233, 30, 196).withOpacity(0.8),
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
                              horizontal: skipButtonWidth * 0.1,
                              vertical: skipButtonHeight * 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(skipButtonHeight / 2),
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
                              fontSize: skipButtonFontSize,
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

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


class CrossPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  CrossPainter({
    this.color = Colors.white,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
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
