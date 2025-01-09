// lib/lobby.dart
class Lobby {
  final String id;
  final String lobbyId;
  final String lobbyName;
  final String type;
  final int numPlayers;
  final int currentPlayers;
  final String creator;
  final bool isLocked;
  final List<String> players;

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
      players: json['players'] is List
          ? List<String>.from(json['players'])
          : [],
    );
  }
}