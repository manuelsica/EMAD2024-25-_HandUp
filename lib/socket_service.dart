// lib/socket_service.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'lobby.dart';
import 'backend_config.dart';

class SocketService {
  late IO.Socket socket;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool _isDisposed = false;
  bool _isListenersInitialized = false;

  // StreamControllers per vari eventi
  final StreamController<List<Lobby>> _lobbiesStreamController = StreamController<List<Lobby>>.broadcast();
  final StreamController<Lobby> _lobbyCreatedStreamController = StreamController<Lobby>.broadcast();
  final StreamController<String> _joinedLobbyStreamController = StreamController<String>.broadcast();
  final StreamController<dynamic> _gameStartedStreamController = StreamController<dynamic>.broadcast();
  final StreamController<String> _voteResultStreamController = StreamController<String>.broadcast();
  final StreamController<void> _startTimerStreamController = StreamController<void>.broadcast();
  final StreamController<void> _gameFinishedStreamController = StreamController<void>.broadcast();

  // Getter per gli stream
  Stream<List<Lobby>> get lobbiesStream => _lobbiesStreamController.stream;
  Stream<Lobby> get lobbyCreatedStream => _lobbyCreatedStreamController.stream;
  Stream<String> get joinedLobbyStream => _joinedLobbyStreamController.stream;
  Stream<dynamic> get gameStartedStream => _gameStartedStreamController.stream;
  Stream<String> get voteResultStream => _voteResultStreamController.stream;
  Stream<void> get startTimerStream => _startTimerStreamController.stream;
  Stream<void> get gameFinishedStream => _gameFinishedStreamController.stream;

  // Listener per gli eventi
  late void Function(dynamic) _updateLobbiesListener;
  late void Function(dynamic) _lobbyCreatedListener;
  late void Function(dynamic) _joinedLobbyListener;
  late void Function(dynamic) _gameStartedListener;
  late void Function(dynamic) _voteResultListener;
  late void Function(dynamic) _startTimerListener;
  late void Function(dynamic) _gameFinishedListener;

  /// Inizializza la connessione Socket.IO
  void connect() async {
    print('Tentativo di lettura del token JWT...');
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      print('Token JWT non trovato: effettua login.');
      return;
    }

    print('Inizializzazione della connessione Socket.IO...');
    socket = IO.io(
      BackendConfig.baseUrl, // 'https://3c45-87-17-154-236.ngrok-free.app/'
      IO.OptionBuilder()
          .setTransports(['websocket']) // Usa solo WebSocket
          .setExtraHeaders({'Authorization': 'Bearer $token'}) // Aggiungi l'header di autorizzazione
          .enableAutoConnect() // Abilita la connessione automatica
          .build(),
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

    socket.on('disconnect', (reason) {
      print('Disconnesso da Socket.IO: $reason');
      if (reason == 'io server disconnect') {
        // La disconnessione è stata iniziata dal server, tentare di riconnettersi
        socket.connect();
      }
    });

    socket.on('error', (data) {
      print('Errore Socket.IO: $data');
    });

    socket.on('connect_error', (data) {
      print('Errore di connessione a Socket.IO: $data');
    });
  }

  /// Disconnette manualmente il socket
  void disconnect() {
    socket.disconnect();
    print('Disconnesso manualmente da Socket.IO');
  }

  /// Metodo generico per ascoltare un evento specifico
  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  /// Emmette l'evento 'create_lobby' con i dati della lobby
  void createLobby(Map<String, dynamic> lobbyData) {
    print('Emettendo evento "create_lobby" con dati: $lobbyData');
    socket.emit('create_lobby', lobbyData);
  }

  /// Emmette l'evento 'join_lobby' per unirsi a una lobby specifica
  void joinLobby(String lobbyId, {String? password}) {
    print('Emettendo evento "join_lobby" per lobbyId: $lobbyId con password: $password');
    socket.emit('join_lobby', {
      'lobby_id': lobbyId,
      'password': password,
    });
  }

  /// Emmette l'evento 'leave_lobby' per lasciare una lobby specifica
  void leaveLobby(String lobbyId) {
    print('Emettendo evento "leave_lobby" per lobbyId: $lobbyId');
    socket.emit('leave_lobby', {
      'lobby_id': lobbyId,
    });
  }

  /// Emmette l'evento 'start_game' per avviare il gioco in una lobby specifica
  void startGame(String lobbyId) {
    print('Emettendo evento "start_game" per lobbyId: $lobbyId');
    socket.emit('start_game', {
      'lobby_id': lobbyId,
    });
  }

  /// Emmette l'evento 'get_lobbies' per ottenere la lista delle lobby
  void getLobbies() {
    print('Emettendo evento "get_lobbies"');
    socket.emit('get_lobbies');
  }

  /// Emmette l'evento 'toggle_ready' per segnalare lo stato di preparazione del giocatore
  void toggleReady(String lobbyId, bool isReady) {
    print('Emettendo evento "toggle_ready" per lobbyId: $lobbyId con isReady: $isReady');
    socket.emit('toggle_ready', {
      'lobby_id': lobbyId,
      'is_ready': isReady,
    });
  }

  /// Emmette l'evento 'vote_mode' per votare la modalità di gioco
  void voteForMode(String lobbyId, String mode) {
    print('Emettendo evento "vote_mode" per lobbyId: $lobbyId con mode: $mode');
    socket.emit('vote_mode', {'lobby_id': lobbyId, 'mode': mode});
  }

  /// Emmette l'evento 'player_on_game_screen' per segnalare di essere arrivati nella GameScreen
  void playerOnGameScreen(String lobbyId) {
    print('Emettendo evento "player_on_game_screen" per lobbyId: $lobbyId');
    socket.emit('player_on_game_screen', {
      'lobby_id': lobbyId,
    });
  }

  /// Configura i listener per gli eventi Socket.IO
  void listenToEvents() {
    print('Registrazione dei listener per gli eventi Socket.IO...');

    // Listener per l'evento 'update_lobbies'
    _updateLobbiesListener = (data) {
      if (_isDisposed) return;
      print('Ricevuto evento "update_lobbies" con dati: $data');
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
        print('Errore nel listener "update_lobbies": $e');
      }
    };

    // Listener per l'evento 'lobby_created'
    _lobbyCreatedListener = (data) {
      if (_isDisposed) return;
      print('Ricevuto evento "lobby_created" con dati: $data');
      if (data['lobby'] is Map<String, dynamic>) {
        Lobby lb = Lobby.fromJson(data['lobby']);
        _lobbyCreatedStreamController.add(lb);
      }
    };

    // Listener per l'evento 'joined_lobby'
    _joinedLobbyListener = (data) {
      if (_isDisposed) return;
      print('Ricevuto evento "joined_lobby" con dati: $data');
      final lobbyId = data['lobby_id'] ?? '';
      _joinedLobbyStreamController.add(lobbyId);
    };

    // Listener per l'evento 'game_started'
    _gameStartedListener = (data) {
      if (_isDisposed) return;
      print('Ricevuto evento "game_started" con dati: $data');
      _gameStartedStreamController.add(data);
    };

    // Listener per l'evento 'vote_result'
    _voteResultListener = (data) {
      if (_isDisposed) return;
      print('Ricevuto evento "vote_result" con dati: $data');
      // data potrebbe contenere { "mode_chosen": "medio" }
      if (data is Map && data["mode_chosen"] is String) {
        print('Modalità scelta: ${data["mode_chosen"]}');
        _voteResultStreamController.add(data["mode_chosen"]);
      }
    };

    // Listener per l'evento 'start_timer'
    _startTimerListener = (data) {
      if (_isDisposed) return;
      print('Ricevuto evento "start_timer" con dati: $data');
      // Emetti sullo stream in modo che la GameScreen possa ascoltare
      _startTimerStreamController.add(null);
    };

    // Listener per l'evento 'game_finished'
    _gameFinishedListener = (data) {
      if (_isDisposed) return;
      print('Ricevuto evento "game_finished" con dati: $data');
      _gameFinishedStreamController.add(null);
    };

    // Registra i listener
    socket.on('update_lobbies', _updateLobbiesListener);
    socket.on('lobby_created', _lobbyCreatedListener);
    socket.on('joined_lobby', _joinedLobbyListener);
    socket.on('game_started', _gameStartedListener);
    socket.on('vote_result', _voteResultListener);
    socket.on('start_timer', _startTimerListener);
    socket.on('game_finished', _gameFinishedListener);
  }

  /// Dispose del servizio SocketService
  void dispose() {
    print('Dispose SocketService...');
    _isDisposed = true;

    // Rimuove i listener
    socket.off('update_lobbies', _updateLobbiesListener);
    socket.off('lobby_created', _lobbyCreatedListener);
    socket.off('joined_lobby', _joinedLobbyListener);
    socket.off('game_started', _gameStartedListener);
    socket.off('vote_result', _voteResultListener);
    socket.off('start_timer', _startTimerListener);
    socket.off('game_finished', _gameFinishedListener);

    // Chiude i StreamControllers
    _lobbiesStreamController.close();
    _lobbyCreatedStreamController.close();
    _joinedLobbyStreamController.close();
    _gameStartedStreamController.close();
    _voteResultStreamController.close();
    _startTimerStreamController.close();
    _gameFinishedStreamController.close();

    // Disconnette il socket
    socket.disconnect();
    print('SocketService dispose completato.');
  }
}