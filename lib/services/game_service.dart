import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';
import '../models/history_item.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  GameModel? _currentGame;

  GameModel? getCurrentGame() => _currentGame;

  GameModel createGame(List<String> players, {bool isVsComputer = false}) {
    final sequence = List.generate(12, (i) => i + 1)..shuffle();
    _currentGame = GameModel(
      gameId: DateTime.now().millisecondsSinceEpoch.toString(),
      players: players,
      sequence: sequence,
      revealed: List.generate(12, (_) => false),
      currentPlayer: players[0],
      nextExpectedNumber: 1,
      status: "ONGOING",
      startTime: DateTime.now().millisecondsSinceEpoch,
      isVsComputer: isVsComputer,
      computerMemory: {},
    );
    return _currentGame!;
  }

  GameModel flipCard(int index) {
    if (_currentGame == null || _currentGame!.status == "FINISHED") return _currentGame!;

    final expected = _currentGame!.nextExpectedNumber;
    final actual = _currentGame!.sequence[index];
    _currentGame!.lastFlippedIndex = index;
    
    // Update computer memory (even if it's not vs computer, it's good practice)
    _currentGame!.computerMemory[index] = actual;

    if (actual == expected) {
      _currentGame!.revealed[index] = true;
      _currentGame!.nextExpectedNumber++;
      _currentGame!.lastMoveCorrect = true;

      if (expected == 12) {
        _currentGame!.status = "FINISHED";
        _currentGame!.winner = _currentGame!.currentPlayer;
        _currentGame!.endTime = DateTime.now().millisecondsSinceEpoch;
        _saveToHistoryAndLeaderboard();
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
    final players = _currentGame!.players;
    final currentIndex = players.indexOf(_currentGame!.currentPlayer);
    final nextIndex = (currentIndex + 1) % players.length;
    _currentGame!.currentPlayer = players[nextIndex];
  }

  int getComputerMove() {
    if (_currentGame == null) return -1;
    
    final expected = _currentGame!.nextExpectedNumber;
    
    // 1. Check memory for the expected number
    for (var entry in _currentGame!.computerMemory.entries) {
      if (entry.value == expected && !_currentGame!.revealed[entry.key]) {
        return entry.key;
      }
    }

    // 2. Otherwise, pick a random unrevealed card
    final unrevealedIndices = <int>[];
    for (int i = 0; i < 12; i++) {
      if (!_currentGame!.revealed[i]) {
        unrevealedIndices.add(i);
      }
    }

    if (unrevealedIndices.isEmpty) return -1;
    
    // Small logic: try to pick something NOT in memory if possible, 
    // unless we have no choice.
    final unknownIndices = unrevealedIndices.where((i) => !_currentGame!.computerMemory.containsKey(i)).toList();
    
    if (unknownIndices.isNotEmpty) {
      return unknownIndices[Random().nextInt(unknownIndices.length)];
    } else {
      return unrevealedIndices[Random().nextInt(unrevealedIndices.length)];
    }
  }

  Future<void> _saveToHistoryAndLeaderboard() async {
    if (_currentGame == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final duration = (_currentGame!.endTime! - _currentGame!.startTime) ~/ 1000;
    
    // Save to Leaderboard (Fastest wins)
    List<String> records = prefs.getStringList('leaderboard') ?? [];
    records.add(json.encode({
      'playerName': _currentGame!.winner,
      'timeInSeconds': duration,
      'date': DateTime.now().toIso8601String(),
    }));
    List<dynamic> leaderBoardDecoded = records.map((r) => json.decode(r)).toList();
    leaderBoardDecoded.sort((a, b) => a['timeInSeconds'].compareTo(b['timeInSeconds']));
    final top3 = leaderBoardDecoded.take(3).map((r) => json.encode(r)).toList();
    await prefs.setStringList('leaderboard', top3);

    // Save to History (Last 20)
    List<String> historyStrings = prefs.getStringList('game_history') ?? [];
    String mode = "2-Player";
    if (_currentGame!.isVsComputer) mode = "Single";
    if (_currentGame!.players.length == 3) mode = "3-Player";

    final historyItem = HistoryItem(
      gameId: _currentGame!.gameId,
      gameMode: mode,
      winner: _currentGame!.winner!,
      scores: {}, // Scores could be cards flipped if we tracked it differently
      dateTime: DateTime.now().toIso8601String(),
      durationSeconds: duration,
    );

    historyStrings.insert(0, json.encode(historyItem.toJson()));
    if (historyStrings.length > 20) {
      historyStrings = historyStrings.take(20).toList();
    }
    await prefs.setStringList('game_history', historyStrings);
  }

  Future<List<dynamic>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList('leaderboard') ?? [];
    return records.map((r) => json.decode(r)).toList();
  }

  Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList('game_history') ?? [];
    return records.map((r) => HistoryItem.fromJson(json.decode(r))).toList();
  }
}
