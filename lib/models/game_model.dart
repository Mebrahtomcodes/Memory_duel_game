class GameModel {
  final String gameId;
  final List<String> players;
  final List<int> sequence;
  List<bool> revealed;
  String currentPlayer;
  int nextExpectedNumber;
  String status;
  String? winner;
  int? lastFlippedIndex;
  bool? lastMoveCorrect;
  int startTime;
  int? endTime;
  final bool isVsComputer;
  Map<int, int> computerMemory; // index -> value

  GameModel({
    required this.gameId,
    required this.players,
    required this.sequence,
    required this.revealed,
    required this.currentPlayer,
    required this.nextExpectedNumber,
    required this.status,
    this.winner,
    this.lastFlippedIndex,
    this.lastMoveCorrect,
    required this.startTime,
    this.endTime,
    this.isVsComputer = false,
    this.computerMemory = const {},
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'players': players,
        'revealed': revealed,
        'sequence': sequence,
        'currentPlayer': currentPlayer,
        'nextExpectedNumber': nextExpectedNumber,
        'status': status,
        'winner': winner,
        'lastFlippedIndex': lastFlippedIndex,
        'lastMoveCorrect': lastMoveCorrect,
        'startTime': startTime,
        'endTime': endTime,
        'isVsComputer': isVsComputer,
      };
}
