import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'socket_service.dart';
import 'lobby_provider.dart';
import 'schermata_lobby.dart';
import 'sidemenu.dart';
import 'app_colors.dart';
import 'top_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'lobby.dart';

class MultiplayerHome extends StatelessWidget {
  const MultiplayerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SocketService>(
          create: (_) => SocketService(),
          dispose: (_, socketService) => socketService.dispose(),
        ),
        ChangeNotifierProxyProvider<SocketService, LobbyProvider>(
          create: (context) => LobbyProvider(
            socketService: Provider.of<SocketService>(context, listen: false),
          ),
          update: (context, socketService, previous) =>
              previous ?? LobbyProvider(socketService: socketService),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundColor,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const MultiplayerHomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
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
  int _nrPlayers = 2;
  String _lobbyName = '';
  String _password = '';

  final storage = const FlutterSecureStorage();
  String _username = "Username";
  int _points = 0;

  late SocketService socketService;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      socketService = Provider.of<SocketService>(context, listen: false);
      socketService.connect();

      socketService.lobbyCreatedStream.listen((lobby) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => LobbyScreen(lobby: lobby),
          ),
        );
      });

      socketService.joinedLobbyStream.listen((lobbyId) {
        final lobbyProvider = Provider.of<LobbyProvider>(context, listen: false);
        final joinedLobby = lobbyProvider.lobbies.firstWhere(
          (l) => l.lobbyId == lobbyId,
          orElse: () => Lobby(
            id: 'unknown',
            lobbyId: lobbyId,
            lobbyName: 'Lobby non trovata',
            type: 'N/D',
            numPlayers: 0,
            currentPlayers: 0,
            creator: '',
            isLocked: false,
            players: [],
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => LobbyScreen(lobby: joinedLobby),
          ),
        );
      });

      await _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    String? username = await storage.read(key: 'username');
    String? pointsStr = await storage.read(key: 'points');

    if (username != null) {
      setState(() {
        _username = username;
      });
    }
    if (pointsStr != null) {
      int? p = int.tryParse(pointsStr);
      if (p != null) {
        setState(() {
          _points = p;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Chiude il container di creazione con animazione
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

  /// Mostra un popup di messaggio
  void _showMessage(String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isError ? 'Errore' : 'Successo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Crea la lobby
  void _createLobby() async {
    // Chiudiamo l’eventuale tastiera
    FocusScope.of(context).unfocus();

    if (_lobbyName.isEmpty) {
      _showMessage('Il nome della lobby è obbligatorio.', isError: true);
      return;
    }

    String? username = await storage.read(key: 'username');
    if (username == null) {
      _showMessage('Username non trovato. Effettua il login.', isError: true);
      return;
    }

    final lobbyData = {
      'lobby_name': _lobbyName,
      'type': _lobbyType,
      'num_players': _nrPlayers,
      'current_players': 1,
      'creator': username,
      'is_locked': _password.isNotEmpty,
      'password': _password.isNotEmpty ? _password : null,
    };

    socketService.createLobby(lobbyData);
    _toggleContainer();
  }

  /// Unisciti alla lobby
  void _joinLobby(String lobbyId, {String? password}) {
    FocusScope.of(context).unfocus();
    socketService.joinLobby(lobbyId, password: password);
  }

  /// Refresh lobbies
  void _refreshLobbies() {
    FocusScope.of(context).unfocus();
    socketService.getLobbies();
  }

  /// Costruisce un tile di una lobby
  Widget _buildLobbyItem({
    required Lobby lobby,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Chiude la tastiera se presente
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.containerOpaqueColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -screenWidth * 0.03,
              top: -screenHeight * 0.05,
              child: Image.asset(
                "assets/swords_icon.png",
                width: screenWidth * 0.2,
                height: screenHeight * 0.2,
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(80, 10, 16, 10),
              title: AppColors.gradientText(lobby.lobbyName, screenWidth * 0.048),
              subtitle: Row(
                children: [
                  CustomPaint(
                    size: Size(screenWidth * 0.04, screenWidth * 0.04),
                    painter: GradientIconPainter(
                      icon: Icons.person,
                      gradient: AppColors.textGradient,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    '${lobby.currentPlayers}/${lobby.numPlayers}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ],
              ),
              trailing: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Owner:',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                    Text(
                      lobby.creator,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    if (lobby.isLocked)
                      CustomPaint(
                        size: Size(screenWidth * 0.035, screenWidth * 0.035),
                        painter: GradientIconPainter(
                          icon: Icons.lock,
                          gradient: AppColors.textGradient,
                        ),
                      )
                  ],
                ),
              ),
              onTap: () {
                if (lobby.isLocked) {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      String pw = '';
                      return AlertDialog(
                        title: const Text('Inserisci Password'),
                        content: TextField(
                          obscureText: true,
                          onSubmitted: (val) {
                            _joinLobby(lobby.lobbyId, password: val);
                            Navigator.of(ctx).pop();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Password',
                          ),
                          onChanged: (val) => pw = val,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _joinLobby(lobby.lobbyId, password: pw);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('OK'),
                          )
                        ],
                      );
                    },
                  );
                } else {
                  _joinLobby(lobby.lobbyId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lobbyProvider = Provider.of<LobbyProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Tocca sfondo -> chiude tastiera
      child: Scaffold(
        drawer: SideMenu(),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  TopBar(
                    username: _username,
                    points: _points,
                    showMenu: true,
                    showUser: true,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _refreshLobbies(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
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
                                    right: -screenWidth * 0.3,
                                    bottom: -screenHeight * 0.35,
                                    child: Image.asset(
                                      'assets/hand_coin.png',
                                      width: screenWidth * 0.8,
                                      height: screenHeight * 0.8,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppColors.gradientText(
                                          "Crea una partita",
                                          screenWidth * 0.07,
                                        ),
                                        const SizedBox(height: 40),
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
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color.fromARGB(110, 214, 57, 196),
                                                    const Color.fromARGB(110, 255, 0, 208),
                                                    const Color.fromARGB(110, 140, 53, 232)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(30),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.transparent,
                                                    blurRadius: 20,
                                                    spreadRadius: 4,
                                                    offset: Offset(0, 0),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
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
                                                onPressed: _toggleContainer,
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 15,
                                                    vertical: 8,
                                                  ),
                                                  child: Text("Crea una Lobby"),
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
                            const SizedBox(height: 20),
                            AppColors.gradientText(
                              "Unisciti ad una Partita",
                              screenWidth * 0.07,
                            ),
                            const SizedBox(height: 10),
                            if (lobbyProvider.lobbies.isEmpty)
                              Center(
                                child: Text(
                                  'Nessuna lobby disponibile. Crea una nuova lobby!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.05,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: lobbyProvider.lobbies.length,
                                itemBuilder: (context, index) {
                                  final lobby = lobbyProvider.lobbies[index];
                                  return _buildLobbyItem(
                                    lobby: lobby,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                  );
                                },
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SlideTransition(
                position: _offsetAnimation,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: screenHeight * 0.6,
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: CustomPaint(
                                  size: const Size(24, 24),
                                  painter: GradientIconPainter(
                                    icon: Icons.close,
                                    gradient: AppColors.textGradient,
                                  ),
                                ),
                                onPressed: _toggleContainer,
                              ),
                            ),
                            AppColors.gradientText(
                              "Crea Lobby",
                              screenWidth * 0.07,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Nome della lobby',
                                hintStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.purple.shade800,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              onChanged: (value) => _lobbyName = value,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade800,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                value: _lobbyType,
                                dropdownColor: Colors.purple.shade800,
                                style: const TextStyle(color: Colors.white),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: <String>["Spelling", "Matematica", "Scarabeo", "Impiccato"]
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _lobbyType = newValue!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade800,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<int>(
                                value: _nrPlayers,
                                dropdownColor: Colors.purple.shade800,
                                style: const TextStyle(color: Colors.white),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: <int>[2, 3, 4].map((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(value.toString()),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _nrPlayers = newValue!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Password (opzionale)',
                                hintStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.purple.shade800,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              onChanged: (value) => _password = value,
                            ),
                            const SizedBox(height: 20),
                            Container(
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
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(110, 214, 57, 196),
                                      const Color.fromARGB(110, 255, 0, 208),
                                      const Color.fromARGB(110, 140, 53, 232)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.transparent,
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: _createLobby,
                                  child: const Text("Crea"),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}