// lib/lobby.dart
class PlayerInfo {
  final String userId;
  final String username;
  final bool isReady;

  PlayerInfo({
    required this.userId,
    required this.username,
    required this.isReady,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      isReady: json['is_ready'] ?? false,
    );
  }
}

class Lobby {
  final String id;
  final String lobbyId;
  final String lobbyName;
  final String type;
  final int numPlayers;
  final int currentPlayers;
  final String creator;
  final bool isLocked;

  // MODIFICA: lista di oggetti PlayerInfo
  final List<PlayerInfo> players;

  Lobby({
    required this.id,
    required this.lobbyId,
    required this.lobbyName,
    required this.type,
    required this.numPlayers,
    required this.currentPlayers,
    required this.creator,
    required this.isLocked,
    required this.players,
  });

  factory Lobby.fromJson(Map<String, dynamic> json) {
    // Costruisce la lista di PlayerInfo da json['players']
    List<PlayerInfo> playerList = [];
    if (json['players'] is List) {
      playerList = (json['players'] as List)
          .map((p) => PlayerInfo.fromJson(p))
          .toList();
    }

    return Lobby(
      id: json['id'] as String? ?? 'unknown_id',
      lobbyId: json['lobby_id'] as String? ?? 'unknown_lobby_id',
      lobbyName: json['lobby_name'] as String? ?? 'Unnamed Lobby',
      type: json['type'] as String? ?? 'Unknown',
      numPlayers: json['num_players'] is int
          ? json['num_players'] as int
          : int.tryParse(json['num_players'].toString()) ?? 0,
      currentPlayers: json['current_players'] is int
          ? json['current_players'] as int
          : int.tryParse(json['current_players'].toString()) ?? 0,
      creator: json['creator'] as String? ?? 'Unknown',
      isLocked: json['is_locked'] as bool? ?? false,
      players: playerList,
    );
  }
}