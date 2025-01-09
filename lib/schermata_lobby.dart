// lib/schermata_lobby.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'socket_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_colors.dart';
import 'lobby.dart';
import 'lobby_provider.dart';

class LobbyScreen extends StatefulWidget {
  final Lobby lobby;

  const LobbyScreen({Key? key, required this.lobby}) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final storage = const FlutterSecureStorage();
  String _currentUserId = '';
  late SocketService socketService; // Variabile membro per SocketService

  @override
  void initState() {
    super.initState();

    // Inizializza socketService qui
    socketService = Provider.of<SocketService>(context, listen: false);

    // Recupera l'ID utente dal secure storage
    _retrieveUserId();

    // Ascolta gli eventi relativi alla lobby tramite LobbyProvider
    // Ad esempio, per aggiornare i giocatori, potresti utilizzare LobbyProvider
  }

  @override
  void dispose() {
    // Se necessario, lasciare la lobby quando il widget viene smontato
    socketService.leaveLobby(widget.lobby.lobbyId);
    super.dispose();
  }

  Future<void> _retrieveUserId() async {
    String? userId = await storage.read(key: 'user_id');
    if (userId != null) {
      setState(() {
        _currentUserId = userId;
      });
    } else {
      // Gestisci il caso in cui l'ID utente non sia disponibile
      _showSnackBar('ID utente non trovato. Effettua il login di nuovo.', isError: true);
    }
  }

  void _startGame() {
    socketService.startGame(widget.lobby.lobbyId);
  }

  void _leaveLobby() {
    socketService.leaveLobby(widget.lobby.lobbyId);
    Navigator.pop(context);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Accedi alla lista dei giocatori tramite LobbyProvider
    final lobbyProvider = Provider.of<LobbyProvider>(context);
    final lobby = lobbyProvider.lobbies.firstWhere((l) => l.lobbyId == widget.lobby.lobbyId, orElse: () => widget.lobby);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(lobby.lobbyName),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _leaveLobby,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Modalità: ${lobby.type}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Numero di Giocatori: ${lobby.currentPlayers}/${lobby.numPlayers}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Partecipanti:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: lobby.players.length,
                itemBuilder: (context, index) {
                  String username = lobby.players[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Text(
                        username[0],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      username,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (lobby.creator == _currentUserId)
              ElevatedButton(
                onPressed: _startGame,
                child: Text('Inizia Partita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textColor1.withOpacity(0.2),
                  foregroundColor: AppColors.textColor1,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}