// lib/schermata_lobby.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_colors.dart';
import 'lobby.dart';
import 'lobby_provider.dart';
import 'socket_service.dart';
import 'select_multiplayer.dart'; 

class LobbyScreen extends StatefulWidget {
  final Lobby lobby;

  const LobbyScreen({Key? key, required this.lobby}) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final storage = const FlutterSecureStorage();
  late SocketService socketService;

  String _currentUsername = '';
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    socketService = Provider.of<SocketService>(context, listen: false);

    _retrieveUsername();
    _listenForLobbyUpdates();
    _listenForGameStarted(); // <-- Modificato per controllare se type == "Spelling"
  }

  @override
  void dispose() {
    if (!_isLeaving) {
      socketService.leaveLobby(widget.lobby.lobbyId);
    }
    super.dispose();
  }

  /// Legge lo username da SecureStorage (usiamo lo username per confrontare se l'utente è owner)
  Future<void> _retrieveUsername() async {
    String? username = await storage.read(key: 'username');
    if (username != null) {
      setState(() {
        _currentUsername = username;
      });
    } else {
      _showSnackBar('Username non trovato. Effettua di nuovo il login.', isError: true);
    }
  }

  /// Ascolta aggiornamenti di lobby (se server emette 'lobby_updated')
  void _listenForLobbyUpdates() {
    socketService.on('lobby_updated', (data) {
      final updatedLobby = Lobby.fromJson(data);
      if (updatedLobby.lobbyId == widget.lobby.lobbyId) {
        Provider.of<LobbyProvider>(context, listen: false).updateLobby(updatedLobby);
      }
    });
  }

  /// Ascolta l'evento 'game_started': se la lobby è "Spelling", naviga a ModalitaScreen.
  /// Altrimenti stampa un debug "Gioco avviato" (es. Scarabeo, Impiccato, ecc.).
  void _listenForGameStarted() {
    socketService.gameStartedStream.listen((data) {
      final startedLobbyId = data['lobby_id'] ?? '';
      if (startedLobbyId == widget.lobby.lobbyId) {
        // Recupera la lobby attuale dal provider, per conoscerne 'type'
        final lobbyProvider = Provider.of<LobbyProvider>(context, listen: false);
        final updatedLobby = lobbyProvider.lobbies.firstWhere(
          (l) => l.lobbyId == widget.lobby.lobbyId,
          orElse: () => widget.lobby,
        );

        if (updatedLobby.type == "Spelling") {
          // Naviga alla schermata delle modalità (già definita)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModalitaScreen(lobbyId: startedLobbyId),
            ),
          );
        } else {
          // Esempio: se non è Spelling, mostra un debug e basta
          debugPrint("Gioco avviato (tipo: ${updatedLobby.type}) - da implementare.");
        }
      }
    });
  }

  /// Uscire dalla lobby
  void _exitLobby() {
    setState(() => _isLeaving = true);
    socketService.leaveLobby(widget.lobby.lobbyId);
    Navigator.pop(context);
  }

  /// Avvia il gioco (solo il creatore)
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
    // Aggiorniamo la lobby con eventuali dati nuovi
    final updatedLobby = lobbyProvider.lobbies.firstWhere(
      (l) => l.lobbyId == widget.lobby.lobbyId,
      orElse: () => widget.lobby,
    );

    final screenWidth = MediaQuery.of(context).size.width;

    // L'owner è chi ha creato la lobby (username)
    final isOwner = (updatedLobby.creator == _currentUsername);

    // Prendi i player NON owner
    final otherPlayers = updatedLobby.players.where((p) => p.username != updatedLobby.creator).toList();
    final allOthersReady = otherPlayers.isNotEmpty && otherPlayers.every((p) => p.isReady);

    // Se c'è solo l'owner in lobby => disabilita "Avvia partita"
    final isSoloOwner = (updatedLobby.currentPlayers == 1);
    final canStart = !isSoloOwner && allOthersReady;

    // Trova me (se non sono owner, posso togglare "Pronto")
    final me = updatedLobby.players.firstWhere(
      (p) => p.username == _currentUsername,
      orElse: () => PlayerInfo(userId: '', username: '', isReady: false),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: _exitLobby,
        ),
        title: Text(
          'Lobby di ${updatedLobby.creator}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Info base sulla lobby
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
                  _buildInfoRow('Nome:', updatedLobby.lobbyName, screenWidth),
                  const SizedBox(height: 10),
                  _buildInfoRow('Modalità:', updatedLobby.type, screenWidth),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'Giocatori:',
                    '${updatedLobby.currentPlayers}/${updatedLobby.numPlayers}',
                    screenWidth,
                  ),
                ],
              ),
            ),

            // Lista giocatori
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: updatedLobby.players.length,
                itemBuilder: (context, index) {
                  final player = updatedLobby.players[index];
                  return _buildParticipantTile(player, screenWidth);
                },
              ),
            ),

            // Se owner -> bottone "Avvia partita" (disabilitato se solo in lobby o se non-owner non pronti)
            if (isOwner)
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
                    onPressed: canStart ? _startGame : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Avvia partita',
                      style: TextStyle(fontSize: screenWidth * 0.045),
                    ),
                  ),
                ),
              )
            else
              // Se NON owner, pulsante "Pronto/Annulla Pronto"
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
                    onPressed: () {
                      // Toggle isReady
                      socketService.toggleReady(
                        updatedLobby.lobbyId,
                        !me.isReady,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      me.isReady ? 'Annulla Pronto' : 'Pronto',
                      style: TextStyle(fontSize: screenWidth * 0.045),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.04,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(PlayerInfo player, double screenWidth) {
    final avatar = player.username.isNotEmpty ? player.username[0] : '?';
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
            backgroundColor: player.isReady ? Colors.green : Colors.purple,
            child: Text(
              avatar,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            player.username,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (player.isReady)
            const Icon(Icons.check, color: Colors.greenAccent),
        ],
      ),
    );
  }
}