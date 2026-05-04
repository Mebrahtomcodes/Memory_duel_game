class HistoryItem {
  final String gameId;
  final String gameMode; // "Single", "2-Player", "3-Player"
  final String winner;
  final Map<String, int> scores; // playerName -> cardsFlipped (optional but good for tracking)
  final String dateTime;
  final int durationSeconds;

  HistoryItem({
    required this.gameId,
    required this.gameMode,
    required this.winner,
    required this.scores,
    required this.dateTime,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'gameMode': gameMode,
        'winner': winner,
        'scores': scores,
        'dateTime': dateTime,
        'durationSeconds': durationSeconds,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      gameId: json['gameId'] ?? '',
      gameMode: json['gameMode'] ?? '',
      winner: json['winner'] ?? '',
      scores: Map<String, int>.from(json['scores'] ?? {}),
      dateTime: json['dateTime'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 0,
    );
  }
}
