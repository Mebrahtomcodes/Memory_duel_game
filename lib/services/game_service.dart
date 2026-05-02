import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
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
      };
}

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  GameModel? _currentGame;

  GameModel? getCurrentGame() => _currentGame;

  GameModel createGame(String playerA, String playerB) {
    final sequence = List.generate(12, (i) => i + 1)..shuffle();
    _currentGame = GameModel(
      gameId: DateTime.now().millisecondsSinceEpoch.toString(),
      players: [playerA, playerB],
      sequence: sequence,
      revealed: List.generate(12, (_) => false),
      currentPlayer: playerA,
      nextExpectedNumber: 1,
      status: "ONGOING",
      startTime: DateTime.now().millisecondsSinceEpoch,
    );
    return _currentGame!;
  }

  GameModel flipCard(int index) {
    if (_currentGame == null || _currentGame!.status == "FINISHED") return _currentGame!;

    final expected = _currentGame!.nextExpectedNumber;
    final actual = _currentGame!.sequence[index];
    _currentGame!.lastFlippedIndex = index;

    if (actual == expected) {
      _currentGame!.revealed[index] = true;
      _currentGame!.nextExpectedNumber++;
      _currentGame!.lastMoveCorrect = true;

      if (expected == 12) {
        _currentGame!.status = "FINISHED";
        _currentGame!.winner = _currentGame!.currentPlayer;
        _currentGame!.endTime = DateTime.now().millisecondsSinceEpoch;
        _saveToLeaderboard(_currentGame!.winner!, _currentGame!.startTime, _currentGame!.endTime!);
      }
    } else {
      _currentGame!.lastMoveCorrect = false;
      _currentGame!.revealed = List.generate(12, (_) => false);
      _currentGame!.nextExpectedNumber = 1;
      _switchTurn();
    }
    return _currentGame!;
  }

  GameModel handleTimeout() {
    if (_currentGame == null || _currentGame!.status == "FINISHED") return _currentGame!;
    _currentGame!.revealed = List.generate(12, (_) => false);
    _currentGame!.nextExpectedNumber = 1;
    _currentGame!.lastMoveCorrect = false;
    _currentGame!.lastFlippedIndex = -1;
    _switchTurn();
    return _currentGame!;
  }

  void _switchTurn() {
    final current = _currentGame!.currentPlayer;
    _currentGame!.currentPlayer = current == _currentGame!.players[0] 
        ? _currentGame!.players[1] 
        : _currentGame!.players[0];
  }

  Future<void> _saveToLeaderboard(String name, int start, int end) async {
    final prefs = await SharedPreferences.getInstance();
    final duration = (end - start) ~/ 1000;
    
    List<String> records = prefs.getStringList('leaderboard') ?? [];
    records.add(json.encode({
      'playerName': name,
      'timeInSeconds': duration,
      'date': DateTime.now().toIso8601String(),
    }));

    // Sort by time and keep top 3
    List<dynamic> decoded = records.map((r) => json.decode(r)).toList();
    decoded.sort((a, b) => a['timeInSeconds'].compareTo(b['timeInSeconds']));
    
    final top3 = decoded.take(3).map((r) => json.encode(r)).toList();
    await prefs.setStringList('leaderboard', top3);
  }

  Future<List<dynamic>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList('leaderboard') ?? [];
    return records.map((r) => json.decode(r)).toList();
  }
}
