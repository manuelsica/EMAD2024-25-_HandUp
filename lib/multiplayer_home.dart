// lib/multiplayer_home.dart
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

class MultiplayerHome extends StatelessWidget {
  const MultiplayerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Fornisce l'istanza di SocketService
        Provider<SocketService>(
          create: (_) => SocketService(),
          dispose: (_, socketService) => socketService.dispose(),
        ),
        // ProxyProvider per fornire LobbyProvider con accesso a SocketService
        ChangeNotifierProxyProvider<SocketService, LobbyProvider>(
          create: (context) => LobbyProvider(
              socketService: Provider.of<SocketService>(context, listen: false)),
          update: (context, socketService, previousLobbyProvider) =>
              previousLobbyProvider ?? LobbyProvider(socketService: socketService),
        ),
        // Aggiungi altri provider qui se necessario
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
  String _username = "Username"; // Valore di default
  int _points = 0; // Valore di default

  late SocketService socketService; // Variabile membro per SocketService

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

    // Accesso a SocketService e recupero dati utente
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      socketService = Provider.of<SocketService>(context, listen: false);
      socketService.connect();
      // Recupera i dati utente
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
    } else {
      print('Username non trovato.');
      // Gestisci l'assenza di username secondo la logica della tua app
    }

    if (pointsStr != null) {
      int? points = int.tryParse(pointsStr);
      if (points != null) {
        setState(() {
          _points = points;
        });
      }
    } else {
      print('Punti non trovati.');
      // Gestisci l'assenza di punti secondo la logica della tua app
    }
  }

  @override
  void dispose() {
    // Rimosso socketService.disconnect(); poiché il Provider gestisce il dispose
    _controller.dispose();
    super.dispose();
  }

  // Funzione per alternare la visibilità del container di creazione della lobby
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

  // Funzione per mostrare messaggi di dialogo
  void _showMessage(String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isError ? 'Errore' : 'Successo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Funzione per creare una lobby
  void _createLobby() async {
    if (_lobbyName.isEmpty) {
      _showMessage('Il nome della lobby è obbligatorio.', isError: true);
      return;
    }

    // Recupera il nome utente corrente dal secure storage
    String? username = await storage.read(key: 'username'); // Assicurati che 'username' sia memorizzato

    if (username == null) {
      _showMessage('Username non trovato. Effettua il login.', isError: true);
      return;
    }

    Map<String, dynamic> lobbyData = {
      'lobby_name': _lobbyName,
      'type': _lobbyType,
      'num_players': _nrPlayers,
      'current_players': 1, // Supponendo che il creatore sia il primo giocatore
      'creator': username,
      'is_locked': _password.isNotEmpty,
      'password': _password.isNotEmpty ? _password : null,
    };

    socketService.createLobby(lobbyData);
    _toggleContainer();
  }

  // Funzione per unirsi a una lobby
  void _joinLobby(String lobbyId, {String? password}) {
    socketService.joinLobby(lobbyId, password: password);
  }

  // Funzione per aggiornare la lista delle lobby
  void _refreshLobbies() {
    socketService.getLobbies();
  }

  // Funzione per costruire un elemento della lista delle lobby
  Widget _buildLobbyItem({
    required String title,
    required String players,
    required String owner,
    required double screenWidth,
    required double screenHeight,
    bool isLocked = false,
    required String lobbyId,
  }) {
    return Consumer<LobbyProvider>(
      builder: (context, lobbyProvider, child) {
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
                title: AppColors.gradientText(title, screenWidth * 0.048),
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
                      players,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
                trailing: SizedBox( // Avvolto in SizedBox per limitare la larghezza
                  width: screenWidth * 0.3, // Regola la larghezza secondo necessità
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min, // Impostato per evitare overflow
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
                          ),
                        )
                    ],
                  ),
                ),
                onTap: () {
                  // Mostra un dialogo per inserire la password se la lobby è protetta
                  if (isLocked) {
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        String inputPassword = '';
                        return AlertDialog(
                          title: const Text('Inserisci Password'),
                          content: TextField(
                            obscureText: true,
                            onChanged: (value) {
                              inputPassword = value;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Password',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                _joinLobby(lobbyId, password: inputPassword);
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Unisciti'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    _joinLobby(lobbyId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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
                  // Barra superiore
                  TopBar(
                      username: _username, // Passa il nome utente reale
                      points: _points, // Passa i punti reali
                      showMenu: true,
                      showUser: true),
                  // Contenuto principale
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _refreshLobbies();
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Sezione per creare una lobby
                            Container(
                              height: screenHeight * 0.3,
                              width: screenWidth * 0.9,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 60, 60),
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
                                  // Immagine di presentazione
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
                                        AppColors.gradientText(
                                            "Crea una partita",
                                            screenWidth * 0.07),
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
                                                  offset:
                                                      const Offset(0, 0),
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
                                                    offset:
                                                        const Offset(0, 0),
                                                  ),
                                                ],
                                              ),
                                              // Bottone per creare una lobby con effetto neon
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                          vertical: 5),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  elevation: 0,
                                                  shadowColor:
                                                      Colors.transparent,
                                                ),
                                                onPressed: _toggleContainer,
                                                child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
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
                            // Sezione per unirsi a una partita
                            AppColors.gradientText(
                                "Unisciti ad una Partita", screenWidth * 0.07),
                            const SizedBox(height: 10),

                            // Lista dinamica delle lobby
                            Consumer<LobbyProvider>(
                              builder: (context, lobbyProvider, child) {
                                if (lobbyProvider.lobbies.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'Nessuna lobby disponibile. Crea una nuova lobby!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: lobbyProvider.lobbies.length,
                                  itemBuilder: (context, index) {
                                    var lobby = lobbyProvider.lobbies[index];
                                    return _buildLobbyItem(
                                      title: lobby.lobbyName,
                                      players:
                                          '${lobby.currentPlayers}/${lobby.numPlayers}',
                                      owner:
                                          lobby.creator, // Assicurati che 'creator' sia l'username
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      isLocked: lobby.isLocked,
                                      lobbyId: lobby.lobbyId,
                                    );
                                  },
                                );
                              },
                            ),
                            // Bottone Indietro (se necessario)
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sezione slide-up per creare una lobby
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
                        // Icona per chiudere la sezione slide-up
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
                            onPressed: () {
                              _toggleContainer();
                            },
                          ),
                        ),
                        AppColors.gradientText(
                            "Crea Lobby", screenWidth * 0.07),
                        SizedBox(height: 20),
                        // Campo di testo per il nome della lobby
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Nome della lobby',
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.purple.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: (value) {
                            _lobbyName = value;
                          },
                        ),
                        SizedBox(height: 20),
                        // Dropdown per selezionare la modalità di gioco
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _lobbyType,
                            hint: const Text(
                              'Seleziona Modalità di Gioco',
                              style: TextStyle(color: Colors.white),
                            ),
                            dropdownColor: Colors.purple.shade800,
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            isExpanded: true,
                            underline: const SizedBox(),
                            menuMaxHeight: 200,
                            onChanged: (String? newValue) {
                              setState(() {
                                _lobbyType = newValue!;
                              });
                            },
                            items: <String>[
                              "Spelling",
                              "Matematica",
                              "Scarabeo",
                              "Impiccato"
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Dropdown per selezionare il numero di giocatori
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<int>(
                            value: _nrPlayers,
                            hint: const Text(
                              'Seleziona Numero di Giocatori',
                              style: TextStyle(color: Colors.white),
                            ),
                            dropdownColor: Colors.purple.shade800,
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            isExpanded: true,
                            underline: const SizedBox(),
                            menuMaxHeight: 200,
                            onChanged: (int? newValue) {
                              setState(() {
                                _nrPlayers = newValue!;
                              });
                            },
                            items: <int>[2, 3, 4]
                                .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Campo di testo per la password opzionale
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Password (opzionale)',
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.purple.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: (value) {
                            _password = value;
                          },
                        ),
                        SizedBox(height: 20),

                        // Bottone per creare la lobby
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
                                  Color.fromARGB(110, 214, 57, 196),
                                  Color.fromARGB(110, 255, 0, 208),
                                  Color.fromARGB(110, 140, 53, 232)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
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
                                backgroundColor: Colors.transparent,
                                foregroundColor:
                                    Colors.white, // Imposta il colore del testo
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: _createLobby,
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    "Crea",
                                  )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
            ],
          ),
        );
      }
    }
