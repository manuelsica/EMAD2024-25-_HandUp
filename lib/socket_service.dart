// lib/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'lobby.dart'; // Assicurati di avere questa classe definita

class SocketService {
  late IO.Socket socket;
  final storage = const FlutterSecureStorage();
  bool _isListenersInitialized = false;
  bool _isDisposed = false;

  // StreamControllers per diversi eventi
  final _lobbiesStreamController = StreamController<List<Lobby>>.broadcast();
  final _lobbyCreatedStreamController = StreamController<Lobby>.broadcast();
  final _gameStartedStreamController = StreamController<dynamic>.broadcast();

  // Riferimenti ai listener per poterli rimuovere
  late void Function(dynamic) _updateLobbiesListener;
  late void Function(dynamic) _lobbyCreatedListener;
  late void Function(dynamic) _gameStartedListener;

  // Getter per gli Stream
  Stream<List<Lobby>> get lobbiesStream => _lobbiesStreamController.stream;
  Stream<Lobby> get lobbyCreatedStream => _lobbyCreatedStreamController.stream;
  Stream<dynamic> get gameStartedStream => _gameStartedStreamController.stream;

  // Connessione al server Socket.IO
  void connect() async {
    String? token = await storage.read(key: 'access_token');

    if (token == null) {
      print('Token JWT non trovato. Effettua il login.');
      return;
    }

    // Connessione al server specificato
    socket = IO.io('https://1d22-95-238-150-172.ngrok-free.app', <String, dynamic>{
      'transports': ['websocket'],
      'extraHeaders': {
        'Authorization': 'Bearer $token',
      },
      'autoConnect': false,
    });

    socket.connect();

    socket.on('connect', (_) {
      print('Connesso al server SocketIO');
      getLobbies();
      if (!_isListenersInitialized) {
        listenToEvents();
        _isListenersInitialized = true;
      }
    });

    socket.on('disconnect', (_) {
      print('Disconnesso dal server SocketIO');
    });

    socket.on('error', (data) {
      print('Errore: $data');
    });
  }

  // Disconnessione dal server
  void disconnect() {
    socket.disconnect();
    print('Disconnesso dal server SocketIO');
  }

  // Metodi per emettere eventi al server
  void createLobby(Map<String, dynamic> lobbyData) {
    socket.emit('create_lobby', lobbyData);
  }

  void joinLobby(String lobbyId, {String? password}) {
    socket.emit('join_lobby', {'lobby_id': lobbyId, 'password': password});
  }

  void leaveLobby(String lobbyId) {
    socket.emit('leave_lobby', {'lobby_id': lobbyId});
  }

  void startGame(String lobbyId) {
    socket.emit('start_game', {'lobby_id': lobbyId});
  }

  void getLobbies() {
    socket.emit('get_lobbies');
  }

  // Ascolto degli eventi dal server e broadcast tramite StreamControllers
  void listenToEvents() {
    _updateLobbiesListener = (data) {
      if (_isDisposed) return;
      try {
        List<Lobby> lobbyList = [];
        if (data['lobbies'] is List) {
          for (var lobbyJson in data['lobbies']) {
            if (lobbyJson is Map<String, dynamic>) {
              lobbyList.add(Lobby.fromJson(lobbyJson));
            } else {
              print('Formato lobby non valido: $lobbyJson');
            }
          }
          _lobbiesStreamController.add(lobbyList);
        } else {
          print('Formato dati lobbies non valido: $data');
        }
      } catch (e, stackTrace) {
        print('Errore durante l\'aggiornamento delle lobby: $e');
        print(stackTrace);
      }
    };

    _lobbyCreatedListener = (data) {
      if (_isDisposed) return;
      print('Lobby creata: $data');
      if (data['lobby'] != null && data['lobby'] is Map<String, dynamic>) {
        Lobby lobby = Lobby.fromJson(data['lobby']);
        _lobbyCreatedStreamController.add(lobby);
      }
    };

    _gameStartedListener = (data) {
      if (_isDisposed) return;
      _gameStartedStreamController.add(data);
    };

    socket.on('update_lobbies', _updateLobbiesListener);
    socket.on('lobby_created', _lobbyCreatedListener);
    socket.on('game_started', _gameStartedListener);
  }

  // Metodo per chiudere gli StreamControllers e rimuovere i listener
  void dispose() {
    _isDisposed = true;

    // Rimuove i listener specifici
    socket.off('update_lobbies', _updateLobbiesListener);
    socket.off('lobby_created', _lobbyCreatedListener);
    socket.off('game_started', _gameStartedListener);

    // Chiude gli StreamControllers
    _lobbiesStreamController.close();
    _lobbyCreatedStreamController.close();
    _gameStartedStreamController.close();

    // Disconnette il socket
    socket.disconnect();
    print('SocketService dispose called');
  }
}