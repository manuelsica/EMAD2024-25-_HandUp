import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animated_button.dart';
import 'package:image/image.dart' as img;
import 'backend_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ScarabeoApp());
}

class ScarabeoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scarabeo Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScarabeoGameScreen(
        playerName: 'Giocatore1',
        opponentName: 'Giocatore2',
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Coordinate {
  final int x;
  final int y;

  Coordinate(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';
}

class SafeCameraPreview extends StatelessWidget {
  final CameraController? controller;

  const SafeCameraPreview({Key? key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }
    return CameraPreview(controller!);
  }
}

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
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late AnimationController _timerController;
  String _timeString = "00:00";
  double _progress = 0.0;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  DateTime _lastSent = DateTime.now();
  bool _isCameraActive = false;
  int _currentTurn = 1;
  int _maxTurns = 15;
  String _detectedSign = '';
  bool _showWordInput = false;
  bool _showReplicaModal = false;
  bool _showJollyInput = false;
  String _currentWord = '';
  String _jollyValue = "_";

  // Rimozione delle caselle "A" e inizializzazione vuota
  List<String> _letters = [];
  List<bool> _letterCompletionStatus = [];

  final String serverURL = BackendConfig.predictUrl;
  bool _isDisposed = false;
  final int gridSize = 15;
  List<List<String?>> board = [];
  List<List<String>> cellTypes = [];
  List<String> playerRack = [];
  List<bool> rackIsWildcard = [];
  String inputWord = "";
  int playerScore = 0;
  Random random = Random();
  int letterBagCount = 0;
  Map<String, int> letterDistribution = {};
  List<Coordinate> selectedPoints = [];
  List<Map<String, dynamic>> usedWildcards = [];
  bool gameOver = false;

  final Map<String, int> letterScores = {
    "A": 1,
    "B": 3,
    "C": 3,
    "D": 2,
    "E": 1,
    "F": 4,
    "G": 2,
    "H": 4,
    "I": 1,
    "L": 1,
    "M": 3,
    "N": 1,
    "O": 1,
    "P": 3,
    "Q": 10,
    "R": 1,
    "S": 1,
    "T": 1,
    "U": 1,
    "V": 4,
    "Z": 8,
    "_": 0
  };

  // Variabile per memorizzare l'ultimo risultato di validazione
  Map<String, dynamic>? _lastValidationResult;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    board = List.generate(gridSize, (_) => List.filled(gridSize, null));
    cellTypes = generateCellTypes();
    initializeGame();
  }

  void _initializeTimer() {
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1),
    )..addListener(() {
        if (_isDisposed) return;
        if (mounted) {
          setState(() {
            _progress = _timerController.value;
            int seconds = (_timerController.value * 60).floor();
            _timeString =
                "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
          });
        }
      });
  }

  Future<void> initializeGame() async {
    final url = Uri.parse("https://dc90-87-2-230-107.ngrok-free.app/initialize_game");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          playerRack = List<String>.from(data['rack']);
          rackIsWildcard = List<bool>.filled(playerRack.length, false);
          letterBagCount = (data['letter_bag_count'] as num).toInt();
          letterDistribution = Map<String, int>.from(data['letter_distribution']);
          board = List.generate(gridSize, (_) => List.filled(gridSize, null));
          selectedPoints = [];
          playerScore = 0;
          usedWildcards = [];
          gameOver = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore nell'inizializzare il gioco.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di connessione al backend.")),
      );
    }
  }

  List<List<String>> generateCellTypes() {
    final tripleWord = [
      Coordinate(0, 0),
      Coordinate(0, 7),
      Coordinate(0, 14),
      Coordinate(7, 0),
      Coordinate(7, 14),
      Coordinate(14, 0),
      Coordinate(14, 7),
      Coordinate(14, 14)
    ];
    final doubleWord = [
      Coordinate(1, 1),
      Coordinate(2, 2),
      Coordinate(3, 3),
      Coordinate(4, 4),
      Coordinate(10, 10),
      Coordinate(11, 11),
      Coordinate(12, 12),
      Coordinate(13, 13),
      Coordinate(1, 13),
      Coordinate(2, 12),
      Coordinate(3, 11),
      Coordinate(4, 10),
      Coordinate(10, 4),
      Coordinate(11, 3),
      Coordinate(12, 2),
      Coordinate(13, 1)
    ];
    final tripleLetter = [
      Coordinate(1, 5),
      Coordinate(1, 9),
      Coordinate(5, 1),
      Coordinate(5, 5),
      Coordinate(5, 9),
      Coordinate(5, 13),
      Coordinate(9, 1),
      Coordinate(9, 5),
      Coordinate(9, 9),
      Coordinate(9, 13),
      Coordinate(13, 5),
      Coordinate(13, 9)
    ];
    final doubleLetter = [
      Coordinate(0, 3),
      Coordinate(0, 11),
      Coordinate(2, 6),
      Coordinate(2, 8),
      Coordinate(3, 0),
      Coordinate(3, 7),
      Coordinate(3, 14),
      Coordinate(6, 2),
      Coordinate(6, 6),
      Coordinate(6, 8),
      Coordinate(6, 12),
      Coordinate(7, 3),
      Coordinate(7, 11),
      Coordinate(8, 2),
      Coordinate(8, 6),
      Coordinate(8, 8),
      Coordinate(8, 12),
      Coordinate(11, 0),
      Coordinate(11, 7),
      Coordinate(11, 14),
      Coordinate(12, 6),
      Coordinate(12, 8),
      Coordinate(14, 3),
      Coordinate(14, 11)
    ];

    List<List<String>> types = List.generate(
        gridSize, (_) => List.generate(gridSize, (_) => '', growable: false),
        growable: false);

    for (var coord in tripleWord) {
      types[coord.y][coord.x] = "3P";
    }

    for (var coord in doubleWord) {
      types[coord.y][coord.x] = "2P";
    }

    for (var coord in tripleLetter) {
      types[coord.y][coord.x] = "3L";
    }

    for (var coord in doubleLetter) {
      types[coord.y][coord.x] = "2L";
    }

    return types;
  }

  Future<void> _startReplication() async {
    FocusScope.of(context).unfocus();
    _closeAllPopups();

    try {
      await _initializeCamera();
      if (_cameraController != null) {
        await _cameraController!.startImageStream(_processCameraImage);
        _isCameraActive = true;
      }
      if (!_isDisposed && mounted) {
        setState(() {
          _showReplicaModal = true;
          _resetTimer();
          _initializeLetterCompletion();
          _timerController.forward();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore nell'inizializzare la fotocamera: $e")),
      );
    }
  }

  Future<void> _stopReplication() async {
    try {
      _isCameraActive = false;
      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
        _cameraController = null;
      }
      if (!_isDisposed && mounted) {
        setState(() {
          _isCameraInitialized = false;
          _showReplicaModal = false;
          _detectedSign = '';
          // Svuota le lettere dopo la chiusura della replica
          _letters = [];
          _letterCompletionStatus = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore nel fermare la fotocamera: $e")),
      );
    }
  }

  Future<void> _initializeCamera() async {
    try {
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

      await _cameraController!.initialize();
      if (_isDisposed) return;
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      throw e;
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (!_isCameraActive || _isDisposed) return;
    final now = DateTime.now();
    if (_isProcessing || now.difference(_lastSent).inMilliseconds < 1000) return;

    _isProcessing = true;
    _lastSent = now;

    try {
      Uint8List? jpegBytes = await _convertCameraImage(image);
      if (jpegBytes != null) {
        Map<String, dynamic>? response = await _sendImageToServer(jpegBytes);
        if (response != null && response.containsKey('predictions')) {
          if (response['predictions'].isNotEmpty) {
            String predictedChar =
                response['predictions'][0]['character'] ?? "Nessuna predizione";
            if (!_isDisposed && mounted) {
              setState(() {
                _detectedSign = predictedChar;
              });
            }
            _handlePredictedCharacter(predictedChar);
          }
        }
      }
    } catch (e) {
      print('Errore nel processare l\'immagine della fotocamera: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<Map<String, dynamic>?> _sendImageToServer(Uint8List imageBytes) async {
    try {
      String base64Image = base64Encode(imageBytes);
      String? jwtToken = await storage.read(key: 'access_token');

      if (jwtToken == null) {
        return null;
      }

      final response = await http.post(
        Uri.parse(serverURL),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode(
            {"image": base64Image, "platform": Platform.isAndroid ? "android" : "ios"}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _convertCameraImage(CameraImage image) async {
    try {
      if (image.planes.isEmpty) return null;

      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420toImageColor(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888toImageColor(image);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Uint8List _convertYUV420toImageColor(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image imgBuffer = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      int uvRow = y >> 1;
      for (int x = 0; x < width; x++) {
        int uvCol = x >> 1;
        int indexY = y * image.planes[0].bytesPerRow + x;
        int indexUV = uvRow * image.planes[1].bytesPerRow +
            uvCol * (image.planes[1].bytesPerPixel ?? 2);

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
        int b = image.planes[0].bytes[byteIndex];
        int g = image.planes[0].bytes[byteIndex + 1];
        int r = image.planes[0].bytes[byteIndex + 2];
        imgBuffer.setPixelRgb(x, y, r, g, b);
      }
    }
    return Uint8List.fromList(img.encodeJpg(imgBuffer, quality: 80));
  }

  void _handleWordButton() {
    _closeAllPopups();
    showWordInputDialog();
  }

  Future<void> _handleReplicaButton() async {
    if (_currentWord.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inserisci una parola prima di replicare.")),
      );
      return;
    }

    // Validare la parola
    Map<String, dynamic> validationResult = await validateWord(_currentWord);

    if (validationResult['isValid']) {
      // Memorizza il risultato della validazione
      _lastValidationResult = validationResult;

      // Avvia la replica solo se la parola è valida
      await _startReplication();
    } else {
      // Mostrare il messaggio di errore specifico dal server
      String errorMessage = validationResult['message'] ?? "Parola non valida!";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _handleJollyValueButton() {
    setState(() {
      _showJollyInput = !_showJollyInput;
    });
  }

  void _closeAllPopups() {
    setState(() {
      _showWordInput = false;
      _showReplicaModal = false;
      _showJollyInput = false;
    });
  }

  void _resetTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  void _initializeLetterCompletion() {
    _letters = _currentWord.toUpperCase().split('');
    _letterCompletionStatus = List<bool>.filled(_letters.length, false);
    setState(() {});
  }

  void _handlePredictedCharacter(String predictedChar) {
    String char = predictedChar.toUpperCase();
    for (int i = 0; i < _letters.length; i++) {
      if (_letters[i] == char && !_letterCompletionStatus[i]) {
        setState(() {
          _letterCompletionStatus[i] = true;
        });
        break;
      }
    }
    if (_letterCompletionStatus.every((status) => status)) {
      _handleAllLettersReplicated();
    }
  }

  void _handleAllLettersReplicated() async {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tutte le lettere sono state replicate!")),
      );

      _updateGameStateAfterReplication();
    }

    await _stopReplication();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timerController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> validateWord(String word) async {
    Map<String, dynamic> result = {
      'isValid': false,
      'score': 0,
      'newRack': [],
      'letterBagCount': 0,
      'letterDistribution': {},
      'wildcardsUsed': [],
      'direction': 'horizontal', // Default
      'position': {'x': 0, 'y': 0}, // Default
      'message': '', // Aggiunto per memorizzare il messaggio di errore
      'word': word.toUpperCase(), // Memorizza la parola
    };

    if (word.isEmpty || selectedPoints.isEmpty) {
      print("validateWord: parola vuota o selectedPoints vuoto");
      return result;
    }

    bool horizontal =
        selectedPoints.every((point) => point.y == selectedPoints.first.y);
    bool vertical =
        selectedPoints.every((point) => point.x == selectedPoints.first.x);
    if (!horizontal && !vertical) {
      print("validateWord: selectedPoints non in linea orizzontale o verticale");
      return result;
    }

    selectedPoints.sort((a, b) =>
        horizontal ? a.x.compareTo(b.x) : a.y.compareTo(b.y));

    int startX = selectedPoints.first.x;
    int startY = selectedPoints.first.y;
    String direction = horizontal ? "horizontal" : "vertical";
    List<Map<String, dynamic>> wildcardsInWord = [];
    List<bool> tempRackIsWildcard = List<bool>.from(rackIsWildcard);

    for (int i = 0; i < word.length; i++) {
      String letter = word[i];
      int rackIndex = playerRack.indexOf(letter);
      if (rackIndex != -1 && tempRackIsWildcard[rackIndex]) {
        int x = direction == "horizontal" ? startX + i : startX;
        int y = direction == "vertical" ? startY + i : startY;
        wildcardsInWord.add({"x": x, "y": y, "letter": letter});
        tempRackIsWildcard[rackIndex] = false;
      }
    }

    Map<String, dynamic> requestBody = {
      "word": word.toUpperCase(),
      "rack": playerRack,
      "direction": direction,
      "position": {"x": startX, "y": startY},
      "selected_cells":
          selectedPoints.map((coord) => {"x": coord.x, "y": coord.y}).toList(),
      "premium_cells": {},
      "wildcards": wildcardsInWord,
    };

    print("validateWord: invio richiesta al server con body: $requestBody");

    final url = Uri.parse("https://dc90-87-2-230-107.ngrok-free.app/validate_word");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("validateWord: risposta del server: $data");
        if (data['valid']) {
          result['isValid'] = true;
          result['score'] = data['score'];
          result['newRack'] = List<String>.from(data['rack']);
          result['letterBagCount'] =
              (data['letter_bag_count'] as num).toInt();
          result['letterDistribution'] =
              Map<String, int>.from(data['letter_distribution']);
          result['wildcardsUsed'] = wildcardsInWord;
          result['direction'] = direction;
          result['position'] = {"x": startX, "y": startY};
        } else {
          // Se la parola non è valida, salva il messaggio di errore
          result['message'] = data['message'] ?? "Parola non valida.";
          print("validateWord: parola non valida secondo il server: ${result['message']}");
        }
      } else {
        print("validateWord: errore di risposta dal server: ${response.statusCode}");
        result['message'] = "Errore di risposta dal server: ${response.statusCode}";
      }
    } catch (e) {
      print('Errore nella validazione della parola: $e');
      result['message'] = "Errore nella validazione della parola: $e";
    }

    return result;
  }

  void showWordInputDialog() {
    setState(() {
      _showWordInput = true;
    });
  }

  Future<void> swapAllLetters() async {
    final url = Uri.parse("https://dc90-87-2-230-107.ngrok-free.app/swap_all_letters");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rack": playerRack}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          playerRack = List<String>.from(data['new_letters']);
          rackIsWildcard = List<bool>.filled(playerRack.length, false);
          letterBagCount = (data['letter_bag_count'] as num).toInt();
          letterDistribution = Map<String, int>.from(data['letter_distribution']);
        });
      } else {
        print("swapAllLetters: errore di risposta dal server: ${response.statusCode}");
      }
    } catch (e) {
      print("Errore di connessione al backend: $e");
    }
  }

  Future<void> handleJolly() async {
    int jollyIndex = playerRack.indexOf('_');
    if (jollyIndex == -1) return;

    String? selectedLetter = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String input = '';
        return AlertDialog(
          title: Text('Scegli una lettera per il Jolly'),
          content: TextField(
            onChanged: (value) => input = value.toUpperCase(),
            maxLength: 1,
            decoration: InputDecoration(hintText: 'Inserisci una lettera'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (RegExp(r'^[A-Z]$').hasMatch(input)) {
                  Navigator.pop(context, input);
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (selectedLetter != null) {
      setState(() {
        playerRack[jollyIndex] = selectedLetter;
        rackIsWildcard[jollyIndex] = true;
      });
    }
  }

  void placeWordOnBoard(String word, String direction, int startX, int startY) {
    for (int i = 0; i < word.length; i++) {
      int x = direction == "horizontal" ? startX + i : startX;
      int y = direction == "vertical" ? startY + i : startY;
      if (y < gridSize && x < gridSize && board[y][x] == null) {
        board[y][x] = word[i];
      }
    }
  }

  Widget _buildLetterTile(String letter, {bool isCompleted = false, int count = 0}) {
    return Stack(
      children: [
        Container(
          width: 50, // Dimensioni secondo l'esempio
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.transparent,
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20, // Dimensione del testo
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
              color: Colors.transparent, // Sfondo trasparente
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white, // Colore del testo
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, VoidCallback onPressed, double screenWidth, double screenHeight) {
    return Flexible(
      child: AnimatedButton(
        onPressed: onPressed,
        isLocked: false,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 233, 30, 196).withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                text,
                style: TextStyle(fontSize: 12), // Riduzione font size
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Funzione per mostrare la distribuzione delle lettere nel bag
  void _showLetterBagDialog() {
    // Ordina le lettere per facilità di lettura
    List<String> sortedLetters = letterDistribution.keys.toList()..sort();

    String distributionText = sortedLetters.map((letter) {
      return '$letter: ${letterDistribution[letter]}';
    }).join('\n');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lettere nel Bag'),
          content: SingleChildScrollView(
            child: Text(distributionText),
          ),
          actions: [
            TextButton(
              child: Text('Chiudi'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Funzione personalizzata per i bottoni di jolly e bag
  Widget _buildActionIconButton(IconData icon, VoidCallback onPressed, double screenWidth, double screenHeight) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: IconButton(
          icon: CustomPaint(
            size: Size(screenWidth * 0.045, screenHeight * 0.045),
            painter: GradientIconPainter(
              icon: icon,
              gradient: AppColors.textGradient,
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget buildGrid() {
  return Center(
    child: Container(
      color: Color(0xFF050E2D),
      padding: EdgeInsets.all(10),
      child: AspectRatio(
        aspectRatio: 1, // Mantiene il tabellone quadrato
        child: GridView.builder(
          shrinkWrap: true, // Riduce la dimensione del GridView al minimo necessario
          physics: NeverScrollableScrollPhysics(), // Disabilita lo scrolling
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            childAspectRatio: 1, // Ogni cella è quadrata
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, index) {
            int x = index % gridSize;
            int y = index ~/ gridSize;
            bool isOccupied = board[y][x] != null;
            bool isSelected = selectedPoints.contains(Coordinate(x, y));

            return GestureDetector(
              onTap: () {
                setState(() {
                  Coordinate coord = Coordinate(x, y);
                  if (selectedPoints.contains(coord)) {
                    selectedPoints.remove(coord);
                  } else {
                    selectedPoints.add(coord);
                  }
                  print("Selezione aggiornata: $selectedPoints");
                });
              },
              child: Container(
                margin: EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isOccupied ? Colors.lightGreen : Colors.yellow)
                      : (isOccupied
                          ? Colors.grey[800]
                          : (cellTypes[y][x] == "3P"
                              ? Colors.red
                              : (cellTypes[y][x] == "2P"
                                  ? Colors.orange
                                  : (cellTypes[y][x] == "3L"
                                      ? Colors.blue
                                      : (cellTypes[y][x] == "2L"
                                          ? Colors.green
                                          : Color(0xFF050E2D)))))),
                  border: Border.all(color: Colors.black, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    board[y][x] ??
                        (cellTypes[y][x] != '' ? cellTypes[y][x] : ""),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isOccupied ? FontWeight.bold : FontWeight.normal,
                      color: cellTypes[y][x] != '' ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

  Widget buildRack() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 4.0,
        children: List<Widget>.generate(playerRack.length, (index) {
          String letter = playerRack[index];
          int score = letterScores[letter] ?? 0;
          return _buildLetterTile(
            letter,
            isCompleted: _letterCompletionStatus.contains(index),
            count: score,
          );
        }),
      ),
    );
  }

  Widget _buildWordInputModal(double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            width: screenWidth * 0.8,
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppColors.gradientText('Inserisci parola', screenWidth * 0.07),
                  SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Inserisci la parola da replicare",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.pink.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.pink),
                      ),
                    ),
                    onChanged: (value) => _currentWord = value.trim(),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildActionButton(
                            "Replica", _handleReplicaButton, screenWidth, screenHeight),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton("Annulla", () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _showWordInput = false;
                            _currentWord = '';
                          });
                        }, screenWidth, screenHeight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplicaModal(double screenWidth, double screenHeight) {
    return WillPopScope(
      onWillPop: () async {
        await _stopReplication();
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.8,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AppColors.gradientText(
                        'Replica della parola', screenWidth * 0.06),
                    SizedBox(height: 16),
                    Container(
                      margin: EdgeInsets.all(screenWidth * 0.01),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: screenWidth * 0.005),
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.03 -
                                screenWidth * 0.005),
                        child: SafeCameraPreview(controller: _cameraController),
                      ),
                    ),
                    SizedBox(height: 16),
                    AppColors.gradientText(
                        'Segno rilevato: $_detectedSign', screenWidth * 0.04),
                    SizedBox(height: 16),
                    Container(
                      height: 60, // Dimensioni ridotte
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _letters
                            .asMap()
                            .entries
                            .map((entry) => _buildLetterTile(
                                entry.value,
                                isCompleted:
                                    _letterCompletionStatus[entry.key],
                                count: letterScores[entry.value] ?? 0))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                    ),
                    SizedBox(height: 16),
                    Text(_timeString, style: TextStyle(color: Colors.white)),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildActionButton("Passa turno", () async {
                            _closeAllPopups();
                            setState(() {
                              _currentTurn++;
                              _resetTimer();
                            });
                            await _stopReplication();
                          }, screenWidth, screenHeight),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton("Annulla", () async {
                            await _stopReplication();
                          }, screenWidth, screenHeight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateGameStateAfterReplication() {
    if (_lastValidationResult != null && _lastValidationResult!['isValid']) {
      setState(() {
        // Aggiorna il punteggio del giocatore
        playerScore += (_lastValidationResult!['score'] as num).toInt();

        // Aggiorna la rack del giocatore
        playerRack = List<String>.from(_lastValidationResult!['newRack']);
        rackIsWildcard = List<bool>.filled(playerRack.length, false);

        // Aggiorna il conteggio delle lettere nel sacchetto
        letterBagCount = (_lastValidationResult!['letterBagCount'] as num).toInt();

        // Aggiorna la distribuzione delle lettere
        letterDistribution =
            Map<String, int>.from(_lastValidationResult!['letterDistribution']);

        // Memorizza la parola prima di resettare
        String word = _lastValidationResult!['word'];
        _currentWord = '';
        _letters = [];
        _letterCompletionStatus = [];

        // Reset del timer
        _resetTimer();

        // Aggiungi la parola al tabellone
        String direction = _lastValidationResult!['direction'] ?? 'horizontal';
        int startX = _lastValidationResult!['position']['x'] ?? 0;
        int startY = _lastValidationResult!['position']['y'] ?? 0;

        placeWordOnBoard(word, direction, startX, startY);

        // Reset di selectedPoints dopo aver posizionato la parola
        selectedPoints = [];
        print("selectedPoints resettato dopo la replica.");
      });

      // Reset del risultato della validazione
      _lastValidationResult = null;
    } else {
      // La parola non è valida, non aggiornare il tabellone né i punti
      // Eventualmente, puoi mostrare un messaggio o gestire il caso come preferisci
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nell'aggiornamento del gioco!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Posizione verticale in alto
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Player\n${widget.playerName}\nScore: $playerScore',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      Column(
                        children: [
                          AppColors.gradientText(
                              'Turno ${_currentTurn}/${_maxTurns}',
                              screenWidth * 0.04),
                          AppColors.gradientText(
                              'È il turno di: ${widget.playerName}',
                              screenWidth * 0.04),
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
                Expanded(
                  child: buildGrid(), // Utilizza Expanded per occupare lo spazio disponibile
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_timeString,
                      style: TextStyle(color: Colors.white)),
                ),
                buildRack(), // Rack posizionato leggermente sotto il timer
                Container(
                  height: 60, // Dimensioni ridotte
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _letters
                        .asMap()
                        .entries
                        .map((entry) => _buildLetterTile(
                            entry.value,
                            isCompleted:
                                _letterCompletionStatus[entry.key],
                            count: letterScores[entry.value] ?? 0))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildActionButton("Parola", _handleWordButton,
                            screenWidth, screenHeight),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton("Cambia tessere", swapAllLetters,
                            screenWidth, screenHeight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottone Jolly allineato in basso a sinistra
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
                  handleJolly(); // Assicurati che questa funzione gestisca correttamente il Jolly
                },
              ),
            ),
          ),
          // Bottone Bag allineato in basso a destra
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
                  _showLetterBagDialog(); // Funzione per mostrare la distribuzione delle lettere
                },
              ),
            ),
          ),
          if (_showWordInput) _buildWordInputModal(screenWidth, screenHeight),
          if (_showReplicaModal) _buildReplicaModal(screenWidth, screenHeight),
        ],
      ),
    );
  }
}