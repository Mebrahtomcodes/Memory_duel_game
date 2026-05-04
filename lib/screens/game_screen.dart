import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/game_service.dart';
import '../models/game_model.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _gameService = GameService();
  late ConfettiController _confettiController;
  
  List<bool> revealed = List.generate(12, (_) => false);
  List<int> sequence = [];
  String currentPlayer = "";
  int lastFlippedIndex = -1;
  bool isProcessing = false;
  bool isComputerThinking = false;

  String gameStatus = "ONGOING";
  int nextExpected = 1;

  Timer? _timer;
  int _secondsLeft = 10;

  Stopwatch _gameStopwatch = Stopwatch();
  Timer? _displayTimer;
  String _formattedTime = "00:00";

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _loadInitialState();
    _gameStopwatch.start();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final duration = _gameStopwatch.elapsed;
        _formattedTime =
            "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      });
    });
  }

  void _loadInitialState() {
    final game = _gameService.getCurrentGame();
    if (game != null) {
      _updateUI(game);
    }
  }

  void _updateUI(GameModel game) {
    if (!mounted) return;
    setState(() {
      revealed = List<bool>.from(game.revealed);
      sequence = List<int>.from(game.sequence);
      currentPlayer = game.currentPlayer;
      gameStatus = game.status;
      nextExpected = game.nextExpectedNumber;

      if (gameStatus == "FINISHED") {
        _confettiController.play();
        _gameStopwatch.stop();
        _displayTimer?.cancel();
        _timer?.cancel();
      } else {
        _startTimer();
        // Check if it's computer's turn
        if (game.isVsComputer && currentPlayer == "Computer" && !isComputerThinking) {
          _handleComputerTurn();
        }
      }
    });
  }

  Future<void> _handleComputerTurn() async {
    if (gameStatus == "FINISHED") return;
    
    setState(() {
      isComputerThinking = true;
    });

    // Loop for consecutive correct moves
    while (currentPlayer == "Computer" && gameStatus == "ONGOING") {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      int index = _gameService.getComputerMove();
      if (index != -1) {
        await flipCard(index);
      } else {
        break;
      }
      
      // Wait for UI to update and check if still computer's turn
      final game = _gameService.getCurrentGame();
      if (game == null || game.currentPlayer != "Computer" || game.status == "FINISHED") {
        break;
      }
    }

    if (mounted) {
      setState(() {
        isComputerThinking = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _displayTimer?.cancel();
    _gameStopwatch.stop();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 10;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    final game = _gameService.handleTimeout();
    _updateUI(game);
  }

  Future<void> flipCard(int index) async {
    if (isProcessing || revealed[index] || gameStatus == "FINISHED") return;

    // Prevent human interaction during computer turn (or if already processing)
    if (currentPlayer == "Computer" && !isComputerThinking) return;

    setState(() {
      isProcessing = true;
    });

    final game = _gameService.flipCard(index);

    if (game.lastMoveCorrect == false && game.lastFlippedIndex != -1) {
      _timer?.cancel();
      setState(() {
        lastFlippedIndex = index;
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    lastFlippedIndex = -1;
    isProcessing = false;
    _updateUI(game);
  }

  Widget buildCard(int index) {
    bool isRevealed = revealed[index] || lastFlippedIndex == index;
    bool isMistake = lastFlippedIndex == index;

    return GestureDetector(
      onTap: () => (currentPlayer == "Computer") ? null : flipCard(index),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isRevealed
              ? (isMistake ? Colors.redAccent : Colors.greenAccent.withOpacity(0.8))
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRevealed ? Colors.transparent : Colors.white24,
            width: 1,
          ),
          boxShadow: [
            if (isRevealed)
              BoxShadow(
                color: (isMistake ? Colors.red : Colors.green).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: Text(
            isRevealed ? "${sequence[index]}" : "?",
            style: TextStyle(
              fontSize: 32,
              color: isRevealed ? Colors.white : Colors.white24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Memory Duel", style: TextStyle(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(_formattedTime,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildTurnIndicator(),
              Expanded(
                child: sequence.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GridView.builder(
                          itemCount: 12,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3),
                          itemBuilder: (context, index) => buildCard(index),
                        ),
                      ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
              createParticlePath: _drawStar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          if (gameStatus == "FINISHED") ...[
            const Icon(Icons.emoji_events, color: Colors.yellow, size: 48),
            const SizedBox(height: 8),
            Text("WINNER: $currentPlayer",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("BACK TO MENU", style: TextStyle(color: Colors.white)),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(currentPlayer,
                              style: const TextStyle(
                                  fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                          if (isComputerThinking) ...[
                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                            ),
                          ],
                        ],
                      ),
                      const Text("CURRENT TURN",
                          style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.5))),
                  child: Column(
                    children: [
                      Text("$nextExpected",
                          style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const Text("NEXT",
                          style: TextStyle(fontSize: 8, color: Colors.white54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _secondsLeft / 10,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _secondsLeft < 4 ? Colors.redAccent : Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text("${_secondsLeft}s",
                    style: TextStyle(
                        color: _secondsLeft < 4 ? Colors.redAccent : Colors.white70,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Path _drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}