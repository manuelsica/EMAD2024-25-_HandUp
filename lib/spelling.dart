// lib/game_screen_spelling.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'risultati_partita.dart'; // Assicurati di avere questa schermata
import 'backend_config.dart';
import 'socket_service.dart';

/// Schermata di gioco per la modalità spelling
class GameScreenSpelling extends StatefulWidget {
  final List<String> words; // Lista di parole da indovinare
  final String lobbyId; // ID della lobby per la sincronizzazione multiplayer

  const GameScreenSpelling({
    Key? key,
    required this.words,
    required this.lobbyId,
  }) : super(key: key);

  @override
  State<GameScreenSpelling> createState() => _GameScreenSpellingState();
}

class _GameScreenSpellingState extends State<GameScreenSpelling> {
  Timer? _timer; // Timer per il countdown
  Duration _remainingTime = const Duration(minutes: 5); // Tempo rimanente
  String _timeString = "05:00"; // Stringa visualizzata per il timer
  late CameraController _cameraController; // Controller della fotocamera
  bool _isCameraInitialized = false; // Stato della fotocamera
  String _predictedCharacter = "Nessuna predizione"; // Carattere predetto dal server
  bool _isProcessing = false; // Stato per evitare richieste duplicate
  DateTime _lastSent = DateTime.now(); // Ultimo invio di immagine al server

  final String serverURL = BackendConfig.predictUrl; // URL per l'endpoint predict
  final storage = const FlutterSecureStorage(); // Istanza per l'accesso al secure storage

  // Variabili per la gestione delle parole e delle lettere
  int _currentWordIndex = 0; // Indice della parola corrente
  List<bool> _letterCompletionStatus = []; // Stato di completamento delle lettere

  // Stato del gioco
  bool _isWaiting = true; // Indica se si è in attesa degli altri giocatori
  bool _isGameFinished = false; // Indica se il gioco è finito

  late SocketService socketService; // Istanza del servizio SocketService

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Inizializza lo stato delle lettere della prima parola
    if (widget.words.isNotEmpty) {
      _initializeLetterCompletion();
    }

    // Ottieni l'istanza di SocketService tramite Provider
    socketService = Provider.of<SocketService>(context, listen: false);

    // Emmetti l'evento 'player_on_game_screen' al server
    socketService.playerOnGameScreen(widget.lobbyId);
    print('Emesso player_on_game_screen per la lobby: ${widget.lobbyId}');

    // Ascolta l'evento 'start_timer' per avviare il timer
    socketService.startTimerStream.listen((_) {
      print('Ricevuto start_timer');
      _startFiveMinuteTimer();
    });

    // Ascolta l'evento 'game_finished' per navigare ai risultati
    socketService.gameFinishedStream.listen((_) {
      print('Ricevuto game_finished');
      _navigateToResults();
    });
  }

  /// Inizializza lo stato di completamento delle lettere per la parola corrente
  void _initializeLetterCompletion() {
    String currentWord = widget.words[_currentWordIndex].toUpperCase();
    _letterCompletionStatus = List<bool>.filled(currentWord.length, false);
  }

  /// Inizializza la fotocamera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.medium, // Usa una risoluzione bilanciata
        enableAudio: false,
      );

      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
      _startImageStream();
      print('Camera inizializzata correttamente');
    } catch (e) {
      print('Errore durante l\'inizializzazione della fotocamera: $e');
    }
  }

  /// Avvia lo stream di immagini dalla fotocamera
  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) async {
      final now = DateTime.now();

      // Processa un frame solo ogni 500 ms
      if (_isProcessing || now.difference(_lastSent).inMilliseconds < 500) {
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
            print('Carattere predetto: $predictedChar');
          } else {
            setState(() {
              _predictedCharacter = "Nessuna mano rilevata";
            });
            print('Nessuna mano rilevata');
          }
        }
      }

      _isProcessing = false;
    });
  }

  /// Gestisce il carattere predetto dal server
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
        print('Lettera $char trovata alla posizione $i');
      }
    }

    // Se tutte le lettere sono state riconosciute, passa alla prossima parola
    if (_letterCompletionStatus.every((status) => status)) {
      print('Tutte le lettere della parola "${widget.words[_currentWordIndex]}" sono state completate');
      _moveToNextWord();
    }
  }

  /// Passa alla prossima parola o termina il gioco
  void _moveToNextWord() {
    if (_currentWordIndex < widget.words.length - 1) {
      setState(() {
        _currentWordIndex++;
        _initializeLetterCompletion();
        _predictedCharacter = "Nessuna predizione";
      });
      print('Passato alla parola successiva: ${widget.words[_currentWordIndex]}');
    } else {
      // Hai completato tutte le parole
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hai completato tutte le parole!")),
      );
      print('Tutte le parole completate, navigazione a RisultatiPartitaScreen');
      _navigateToResults();
    }
  }

  /// Invia l'immagine convertita al server per la predizione
  Future<Map<String, dynamic>?> _sendImageToServer(Uint8List imageBytes) async {
    try {
      print('Inviando immagine al server...');
      String base64Image = base64Encode(imageBytes);
      String platform = Platform.isAndroid ? "android" : "ios";

      // Recupera il token JWT salvato
      String? jwtToken = await storage.read(key: 'access_token');

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

      print('Effettuando richiesta POST a $serverURL');
      final response = await http.post(
        Uri.parse(serverURL),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({"image": base64Image, "platform": platform}),
      );

      print('Risposta del server: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Risposta del server: ${response.body}');
        return jsonDecode(response.body);
      } else {
        print("Errore dal server: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore dal server: ${response.body}")),
        );
        return null;
      }
    } catch (e) {
      print("Errore nella richiesta al server: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore nella richiesta al server: $e")),
      );
      return null;
    }
  }

  /// Converte l'immagine della fotocamera in formato JPEG
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

  /// Converte un'immagine YUV420 in formato JPEG
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

        if (indexUV + 1 >= image.planes[1].bytes.length || indexY >= image.planes[0].bytes.length) {
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

  /// Converte un'immagine BGRA8888 in formato JPEG
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

  /// Costruisce un bottone per una lettera specifica
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
          color: isCompleted
              ? Colors.green
              : AppColors.textColor1.withOpacity(0.3),
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

  /// Avvia il timer di 5 minuti
  void _startFiveMinuteTimer() {
    if (_timer == null || !_timer!.isActive) {
      setState(() {
        _isWaiting = false;
        _remainingTime = const Duration(minutes: 5);
        _timeString = "05:00";
      });
      print('Avvio del timer di 5 minuti');

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime.inSeconds > 0) {
          setState(() {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
            _timeString =
                "${(_remainingTime.inMinutes).toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}";
          });
          print('Timer aggiornato: $_timeString');
        } else {
          timer.cancel();
          print('Timer terminato, navigazione a RisultatiPartitaScreen');
          _navigateToResults();
        }
      });
    }
  }

  /// Naviga alla schermata dei risultati
  void _navigateToResults() {
    if (!_isGameFinished) {
      setState(() {
        _isGameFinished = true;
      });
      print('Navigazione a RisultatiPartitaScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RisultatiPartitaScreen(),
        ),
      );
    }
  }

  /// Finisce il gioco manualmente (opzionale)
  void _finishGame() {
    _navigateToResults();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          child: _isWaiting
              ? _buildWaitingUI()
              : Column(
                  children: [
                    // Barra di progresso
                    Container(
                      margin: EdgeInsets.fromLTRB(padding, padding, padding, padding / 2),
                      height: progressBarHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(progressBarHeight / 2),
                      ),
                      child: LinearProgressIndicator(
                        value: 1.0 - (_remainingTime.inSeconds / 300),
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(
                                AppColors.textColor1,
                                AppColors.textColor3,
                                1.0 - (_remainingTime.inSeconds / 300),
                              ) ??
                              AppColors.textColor1,
                        ),
                      ),
                    ),

                    // Feed della fotocamera
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

                    // Carattere predetto
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      child: AppColors.gradientText(
                        "Segno rilevato: $_predictedCharacter",
                        predictedTextFontSize,
                      ),
                    ),

                    // Bottoni per le lettere della parola corrente
                    Container(
                      margin: EdgeInsets.all(padding),
                      height: optionButtonSize,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.words[_currentWordIndex]
                            .toUpperCase()
                            .split('')
                            .asMap()
                            .entries
                            .map((entry) {
                          int idx = entry.key;
                          String letter = entry.value;
                          bool isCompleted = _letterCompletionStatus[idx];
                          return Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: padding * 0.1),
                              child: _buildOptionButton(
                                  letter,
                                  optionButtonSize,
                                  optionButtonBorderRadius,
                                  isCompleted),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Controlli inferiori (Indietro, Timer, Skip)
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
                          Container(
                            width: skipButtonWidth,
                            height: skipButtonHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(skipButtonHeight / 2),
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
                                textAlign: TextAlign.center,
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

  /// Costruisce la UI mostrata mentre si aspetta che tutti i giocatori siano presenti
  Widget _buildWaitingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            "Attesa player...",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter per icone con gradiente
class GradientIconPainter extends CustomPainter {
  final IconData icon;
  final Gradient gradient;

  GradientIconPainter({
    required this.icon,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size.width,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white, // Questo colore verrà sovrascritto dal shader
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(0, (size.height - textPainter.height) / 2),
    );

    // Crea una maschera per applicare il gradiente solo all'icona
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}