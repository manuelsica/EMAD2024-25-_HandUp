import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_colors.dart';
import 'lobby.dart';
import 'lobby_provider.dart';
import 'socket_service.dart';

class LobbyScreen extends StatefulWidget {
  final Lobby lobby;

  const LobbyScreen({Key? key, required this.lobby}) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final storage = const FlutterSecureStorage();
  String _currentUserId = '';
  late SocketService socketService;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    socketService = Provider.of<SocketService>(context, listen: false);
    _retrieveUserId();
    _listenForLobbyUpdates();
  }

  @override
  void dispose() {
    if (!_isLeaving) {
      socketService.leaveLobby(widget.lobby.lobbyId);
    }
    super.dispose();
  }

  Future<void> _retrieveUserId() async {
    String? userId = await storage.read(key: 'user_id');
    if (userId != null) {
      setState(() {
        _currentUserId = userId;
      });
    } else {
      _showSnackBar('ID utente non trovato. Effettua di nuovo il login.', isError: true);
    }
  }

  void _listenForLobbyUpdates() {
    // Se vuoi intercettare un evento di aggiornamento specifico
    socketService.on('lobby_updated', (data) {
      final updatedLobby = Lobby.fromJson(data);
      if (updatedLobby.lobbyId == widget.lobby.lobbyId) {
        Provider.of<LobbyProvider>(context, listen: false).updateLobby(updatedLobby);
      }
    });
  }

  void _exitLobby() {
    setState(() => _isLeaving = true);
    socketService.leaveLobby(widget.lobby.lobbyId);
    Navigator.pop(context);
  }

  void _startGame() {
    socketService.startGame(widget.lobby.lobbyId);
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
    final lobbyProvider = Provider.of<LobbyProvider>(context);
    final lobby = lobbyProvider.lobbies.firstWhere(
      (l) => l.lobbyId == widget.lobby.lobbyId,
      orElse: () => widget.lobby,
    );

    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // chiude la tastiera
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _exitLobby,
          ),
          title: Text(
            'Lobby di ${lobby.creator}',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Esempio di informazioni
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.purple.shade900.withOpacity(0.3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Nome:', lobby.lobbyName, screenWidth),
                    const SizedBox(height: 10),
                    _buildInfoRow('Modalità:', lobby.type, screenWidth),
                    const SizedBox(height: 10),
                    _buildInfoRow('Giocatori:', '${lobby.currentPlayers}/${lobby.numPlayers}', screenWidth),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lobby.players.length,
                  itemBuilder: (context, index) {
                    final username = lobby.players[index];
                    return _buildParticipantTile(username, username[0], screenWidth);
                  },
                ),
              ),

              // Se l’utente è il creatore
              if (lobby.creator == _currentUserId)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Inizia Partita',
                        style: TextStyle(fontSize: screenWidth * 0.045),
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

  Widget _buildInfoRow(String label, String value, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            )),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(String username, String avatar, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.purple.shade900.withOpacity(0.3),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: Text(
              avatar,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            username,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}