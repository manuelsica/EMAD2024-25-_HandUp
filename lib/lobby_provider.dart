// lib/lobby_provider.dart
import 'package:flutter/material.dart';
import 'lobby.dart';
import 'socket_service.dart';

class LobbyProvider with ChangeNotifier {
  final SocketService socketService;
  List<Lobby> _lobbies = [];

  LobbyProvider({required this.socketService}) {
    // Ascolta gli eventi di aggiornamento delle lobby
    socketService.lobbiesStream.listen((lobbyList) {
      _lobbies = lobbyList;
      notifyListeners();
    });

    // Ascolta gli eventi di creazione di una nuova lobby
    socketService.lobbyCreatedStream.listen((lobby) {
      _lobbies.add(lobby);
      notifyListeners();
    });

    // Ascolta gli eventi di avvio del gioco (se necessario)
    socketService.gameStartedStream.listen((data) {
      // Puoi gestire ulteriori azioni qui, come notifiche o navigazione
      print('Il gioco è iniziato: $data');
      // Nota: Evita di navigare direttamente qui
    });
  }

  List<Lobby> get lobbies => _lobbies;

  void setLobbies(List<Lobby> newLobbies) {
    _lobbies = newLobbies;
    notifyListeners();
  }

  void addLobby(Lobby lobby) {
    _lobbies.add(lobby);
    notifyListeners();
  }

  void updateLobby(Lobby updatedLobby) {
    int index = _lobbies.indexWhere((lobby) => lobby.id == updatedLobby.id);
    if (index != -1) {
      _lobbies[index] = updatedLobby;
      notifyListeners();
    }
  }

  void removeLobby(String lobbyId) {
    _lobbies.removeWhere((lobby) => lobby.id == lobbyId);
    notifyListeners();
  }
}