import 'package:flutter/material.dart';
import '../models/history_item.dart';
import '../services/game_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GameService _gameService = GameService();
  List<HistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _gameService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Game History"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            "No games played yet.",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final date = DateTime.parse(item.dateTime);
    final formattedDate = DateFormat('MMM d, yyyy • HH:mm').format(date);
    
    Color modeColor = Colors.blue;
    if (item.gameMode == "Single") modeColor = Colors.blueAccent;
    if (item.gameMode == "2-Player") modeColor = Colors.greenAccent;
    if (item.gameMode == "3-Player") modeColor = Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.gameMode.toUpperCase(),
                  style: TextStyle(color: modeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.yellow, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("WINNER", style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text(
                      item.winner,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("DURATION", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(
                    "${item.durationSeconds}s",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
