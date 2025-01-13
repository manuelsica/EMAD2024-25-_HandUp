// lib/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'lobby.dart'; 

class SocketService {
  late IO.Socket socket;
  final storage = const FlutterSecureStorage();

  bool _isDisposed = false;
  bool _isListenersInitialized = false;

  final _lobbiesStreamController      = StreamController<List<Lobby>>.broadcast();
  final _lobbyCreatedStreamController = StreamController<Lobby>.broadcast();
  final _joinedLobbyStreamController  = StreamController<String>.broadcast();
  final _gameStartedStreamController  = StreamController<dynamic>.broadcast();

  Stream<List<Lobby>> get lobbiesStream => _lobbiesStreamController.stream;
  Stream<Lobby> get lobbyCreatedStream  => _lobbyCreatedStreamController.stream;
  Stream<String> get joinedLobbyStream  => _joinedLobbyStreamController.stream;
  Stream<dynamic> get gameStartedStream => _gameStartedStreamController.stream;

  late void Function(dynamic) _updateLobbiesListener;
  late void Function(dynamic) _lobbyCreatedListener;
  late void Function(dynamic) _joinedLobbyListener;
  late void Function(dynamic) _gameStartedListener;

  void connect() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      print('Token JWT non trovato: effettua login.');
      return;
    }

    socket = IO.io(
      'https://c8ed-87-17-154-236.ngrok-free.app',
      <String, dynamic>{
        'transports': ['websocket'],
        'extraHeaders': {
          'Authorization': 'Bearer $token',
        },
        'autoConnect': false,
      },
    );

    socket.connect();

    socket.on('connect', (_) {
      print('Connesso a Socket.IO');
      getLobbies();
      if (!_isListenersInitialized) {
        listenToEvents();
        _isListenersInitialized = true;
      }
    });

    socket.on('disconnect', (_) {
      print('Disconnesso da Socket.IO');
    });

    socket.on('error', (data) {
      print('Errore Socket.IO: $data');
    });
  }

  void disconnect() {
    socket.disconnect();
    print('Disconnesso manualmente da Socket.IO');
  }

  /// 👉 Metodo per registrare listener dinamici su eventi specifici
  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void createLobby(Map<String, dynamic> lobbyData) {
    socket.emit('create_lobby', lobbyData);
  }

  void joinLobby(String lobbyId, {String? password}) {
    socket.emit('join_lobby', {
      'lobby_id': lobbyId,
      'password': password,
    });
  }

  void leaveLobby(String lobbyId) {
    socket.emit('leave_lobby', {
      'lobby_id': lobbyId,
    });
  }

  void startGame(String lobbyId) {
    socket.emit('start_game', {
      'lobby_id': lobbyId,
    });
  }

  void getLobbies() {
    socket.emit('get_lobbies');
  }

  void listenToEvents() {
    _updateLobbiesListener = (data) {
      if (_isDisposed) return;
      try {
        List<Lobby> list = [];
        if (data['lobbies'] is List) {
          for (var lbJson in data['lobbies']) {
            if (lbJson is Map<String, dynamic>) {
              list.add(Lobby.fromJson(lbJson));
            }
          }
        }
        _lobbiesStreamController.add(list);
      } catch (e) {
        print('Errore update_lobbies: $e');
      }
    };

    _lobbyCreatedListener = (data) {
      if (_isDisposed) return;
      print('lobby_created: $data');
      if (data['lobby'] is Map<String, dynamic>) {
        Lobby lb = Lobby.fromJson(data['lobby']);
        _lobbyCreatedStreamController.add(lb);
      }
    };

    _joinedLobbyListener = (data) {
      if (_isDisposed) return;
      print('joined_lobby: $data');
      final lobbyId = data['lobby_id'] ?? '';
      _joinedLobbyStreamController.add(lobbyId);
    };

    _gameStartedListener = (data) {
      if (_isDisposed) return;
      print('game_started: $data');
      _gameStartedStreamController.add(data);
    };

    socket.on('update_lobbies', _updateLobbiesListener);
    socket.on('lobby_created', _lobbyCreatedListener);
    socket.on('joined_lobby', _joinedLobbyListener);
    socket.on('game_started', _gameStartedListener);
  }

  void dispose() {
    _isDisposed = true;

    socket.off('update_lobbies', _updateLobbiesListener);
    socket.off('lobby_created', _lobbyCreatedListener);
    socket.off('joined_lobby', _joinedLobbyListener);
    socket.off('game_started', _gameStartedListener);

    _lobbiesStreamController.close();
    _lobbyCreatedStreamController.close();
    _joinedLobbyStreamController.close();
    _gameStartedStreamController.close();

    socket.disconnect();
    print('SocketService dispose');
  }
}