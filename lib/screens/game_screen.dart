import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/game_service.dart';

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
      }
    });
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
      onTap: () => flipCard(index),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isRevealed
              ? (isMistake ? Colors.red : Colors.green)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (!isRevealed)
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
          ],
        ),
        child: Center(
          child: Text(
            isRevealed ? "${sequence[index]}" : "?",
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
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
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text("Memory Duel"),
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
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    if (gameStatus == "FINISHED") ...[
                      Text("WINNER: $currentPlayer 🎉",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                        child: const Text("Start New Game",
                            style: TextStyle(fontSize: 18)),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Turn: $currentPlayer",
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text("Time left: $_secondsLeft s",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: _secondsLeft < 4
                                          ? Colors.redAccent
                                          : Colors.white70)),
                            ],
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text("Next: $nextExpected",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                              value: _secondsLeft / 10,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _secondsLeft < 4
                                      ? Colors.redAccent
                                      : Colors.blue))),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: sequence.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3),
                        itemBuilder: (context, index) => buildCard(index),
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
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              createParticlePath: _drawStar,
            ),
          ),
        ],
      ),
    );
  }

  /// A custom Path to paint stars.
  Path _drawStar(Size size) {
    // Method to convert degree to radians
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
